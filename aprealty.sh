#!/bin/sh

green="\033[32m"
red="\033[31m"
re="\033[0m"

XRAY_BIN="/usr/local/bin/xray"
CONFIG_DIR="/usr/local/etc/xray"
CONFIG_FILE="$CONFIG_DIR/config.json"
LIST_FILE="$CONFIG_DIR/node.txt"
KEEPALIVE_SCRIPT="/usr/local/bin/xray_keepalive.sh"

install_deps() {
    echo -e "${green}安装依赖...${re}"
    apk add -q --no-cache bash curl wget unzip openssl iproute2 >/dev/null 2>&1
}

install_xray() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${red}已检测到安装，请先卸载！${re}"
        return
    fi

    mkdir -p "$CONFIG_DIR" /usr/local/bin
    echo -e "${green}下载并安装 Xray...${re}"

    # 固定版本 v25.8.3 musl 64 位
    wget -O /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v25.8.3/Xray-linux-musl-64.zip
    unzip -qo /tmp/xray.zip -d /usr/local/bin
    chmod +x $XRAY_BIN

    if [ ! -x "$XRAY_BIN" ]; then
        echo -e "${red}Xray 安装失败，请检查下载链接或系统架构${re}"
        exit 1
    fi

    read -p "请输入端口 (默认 443): " input_port
    PORT=${input_port:-443}
    read -p "请输入 SNI 域名 (默认 www.yahoo.com): " input_sni
    SNI=${input_sni:-www.yahoo.com}

    UUID=$(cat /proc/sys/kernel/random/uuid)
    KEYS=$($XRAY_BIN x25519)
    PrivateKey=$(echo "$KEYS" | sed -n 's/.*Private Key: //p')
    PublicKey=$(echo "$KEYS" | sed -n 's/.*Public Key: //p')
    shortid=$(openssl rand -hex 8)

    if [ -z "$PrivateKey" ] || [ -z "$PublicKey" ]; then
        echo -e "${red}生成密钥失败，请检查 Xray 可执行文件${re}"
        exit 1
    fi

    cat > $CONFIG_FILE <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {"id": "$UUID","flow": "xtls-rprx-vision"}
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "listen": "0.0.0.0",
        "realitySettings": {
          "show": false,
          "dest": "1.1.1.1:443",
          "xver": 0,
          "serverNames": ["$SNI"],
          "privateKey": "$PrivateKey",
          "shortIds": ["$shortid"]
        }
      }
    }
  ]
}
EOF

    restart_xray
    check_node
}

restart_xray() {
    pkill -f "$XRAY_BIN" >/dev/null 2>&1
    nohup $XRAY_BIN -c $CONFIG_FILE >/dev/null 2>&1 &
    sleep 2
    update_node
    start_keepalive
}

update_node() {
    UUID=$(sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' $CONFIG_FILE)
    PORT=$(sed -n 's/.*"port": *\([0-9]*\).*/\1/p' $CONFIG_FILE)
    PublicKey=$(sed -n 's/.*"privateKey": *"\([^"]*\)".*/\1/p' $CONFIG_FILE)
    shortid=$(sed -n 's/.*"shortIds": *\["\([^"]*\)".*/\1/p' $CONFIG_FILE)
    sni=$(sed -n 's/.*"serverNames": *\["\([^"]*\)".*/\1/p' $CONFIG_FILE)
    IP=$(curl -s ipv4.ip.sb)
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

    cat > $LIST_FILE <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sni}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF
}

start_keepalive() {
    pkill -f "$KEEPALIVE_SCRIPT" >/dev/null 2>&1
    cat > $KEEPALIVE_SCRIPT <<'EOF'
#!/bin/sh
CONFIG_FILE="/usr/local/etc/xray/config.json"
XRAY_BIN="/usr/local/bin/xray"
while true; do
    if ! pgrep -f "$XRAY_BIN" >/dev/null 2>&1; then
        nohup $XRAY_BIN -c $CONFIG_FILE >/dev/null 2>&1 &
    fi
    sleep 5
done
EOF
    chmod +x $KEEPALIVE_SCRIPT
    nohup $KEEPALIVE_SCRIPT >/dev/null 2>&1 &
}

check_node() {
    PORT=$(sed -n 's/.*"port": *\([0-9]*\).*/\1/p' $CONFIG_FILE)
    IP=$(curl -s ipv4.ip.sb)
    echo -e "${green}检查端口 $PORT 是否开放...${re}"
    if nc -zv -w3 $IP $PORT >/dev/null 2>&1; then
        echo -e "${green}端口开放，可连接！${re}"
    else
        echo -e "${red}端口未开放或被阻塞！${re}"
    fi
    echo -e "${green}节点信息:${re}"
    cat $LIST_FILE
}

show_menu() {
    clear
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}  VLESS Reality Alpine 安装脚本${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}1) 安装并校验节点${re}"
    echo -e "${green}2) 更换端口${re}"
    echo -e "${green}3) 修改 SNI${re}"
    echo -e "${green}4) 修改 UUID${re}"
    echo -e "${green}5) 查看节点${re}"
    echo -e "${green}6) 卸载${re}"
    echo -e "${green}0) 退出${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    read -p "请输入选项: " num
    case "$num" in
        1) install_deps; install_xray ;;
        2) read -p "请输入新端口: " p; sed -i "s/\"port\": [0-9]\+/\"port\": $p/" $CONFIG_FILE; restart_xray; check_node ;;
        3) read -p "请输入新 SNI: " s; sed -i "s/\"serverNames\": \[\".*\"\]/\"serverNames\": [\"$s\"]/" $CONFIG_FILE; restart_xray; check_node ;;
        4) new_uuid=$(cat /proc/sys/kernel/random/uuid); sed -i "s/\"id\": \".*\"/\"id\": \"$new_uuid\"/" $CONFIG_FILE; restart_xray; check_node ;;
        5) cat $LIST_FILE ;;
        6) pkill -f "$XRAY_BIN"; pkill -f "$KEEPALIVE_SCRIPT"; rm -rf $XRAY_BIN $CONFIG_DIR $KEEPALIVE_SCRIPT; echo -e "${green}已卸载完成！${re}" ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项！${re}" ;;
    esac
    read -p "按回车返回菜单..." enter
    show_menu
}

show_menu
