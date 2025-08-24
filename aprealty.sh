#!/bin/sh

# ================== 颜色定义 ==================
green="\033[32m"
red="\033[31m"
re="\033[0m"

XRAY_BIN="/usr/local/bin/xray"
CONFIG_DIR="/usr/local/etc/xray"
CONFIG_FILE="$CONFIG_DIR/config.json"
LIST_FILE="$CONFIG_DIR/node.txt"
KEEPALIVE_SCRIPT="/usr/local/bin/xray_keepalive.sh"

# ================== 安装依赖 ==================
install_deps() {
    echo -e "${green}安装依赖...${re}"
    apk add -q --no-cache bash curl wget unzip openssl iproute2 openntpd >/dev/null 2>&1
    ntpd -q -p pool.ntp.org >/dev/null 2>&1
}

# ================== 安装 Xray ==================
install_xray() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${red}已检测到安装，请先卸载！${re}"
        return
    fi
    mkdir -p "$CONFIG_DIR"
    echo -e "${green}下载并安装 Xray...${re}"
    wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -O /tmp/xray.zip
    unzip -qo /tmp/xray.zip -d /usr/local/bin
    chmod +x $XRAY_BIN

    # 用户自定义端口和 SNI
    read -p "请输入端口 (默认 443): " input_port
    PORT=${input_port:-443}
    read -p "请输入 SNI 域名 (必须可访问 HTTPS，默认 www.yahoo.com): " input_sni
    SNI=${input_sni:-www.yahoo.com}

    # 生成 UUID / Key / shortid
    UUID=$(cat /proc/sys/kernel/random/uuid)
    KEYS=$($XRAY_BIN x25519)
    PrivateKey=$(echo "$KEYS" | sed -n 's/.*Private Key: //p')
    PublicKey=$(echo "$KEYS" | sed -n 's/.*Public Key: //p')
    shortid=$(openssl rand -hex 8)

    if [ -z "$PublicKey" ] || [ -z "$PrivateKey" ]; then
        echo -e "${red}生成密钥失败，请检查 Xray 可执行文件${re}"
        exit 1
    fi

    # 生成配置文件，监听 IPv4 + IPv6
    cat > $CONFIG_FILE <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
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

# ================== 更新节点信息 ==================
update_node() {
    UUID=$(sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' $CONFIG_FILE | head -n1)
    PORT=$(sed -n 's/.*"port": *\([0-9]*\).*/\1/p' $CONFIG_FILE | head -n1)
    PublicKey=$(sed -n 's/.*"privateKey": *"\([^"]*\)".*/\1/p' $CONFIG_FILE | head -n1)
    shortid=$(sed -n 's/.*"shortIds": *\["\([^"]*\)".*/\1/p' $CONFIG_FILE | head -n1)
    sni=$(sed -n 's/.*"serverNames": *\["\([^"]*\)".*/\1/p' $CONFIG_FILE | head -n1)
    IP=$(curl -s ipv4.ip.sb)
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

    cat > $LIST_FILE <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sni}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF
}

# ================== 保活脚本 ==================
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

# ================== 重启 Xray ==================
restart_xray() {
    pkill -f "$XRAY_BIN" >/dev/null 2>&1
    nohup $XRAY_BIN -c $CONFIG_FILE >/dev/null 2>&1 &
    sleep 2
    update_node
    start_keepalive
}

# ================== 检查端口和节点可用性 ==================
check_node() {
    IP=$(curl -s ipv4.ip.sb)
    PORT=$(sed -n 's/.*"port": *\([0-9]*\).*/\1/p' $CONFIG_FILE | head -n1)
    echo -e "${green}检查端口 $PORT 是否开放...${re}"
    if nc -zv -w3 $IP $PORT >/dev/null 2>&1; then
        echo -e "${green}端口开放，可连接！${re}"
    else
        echo -e "${red}端口未开放或被阻塞！${re}"
    fi

    echo -e "${green}节点信息:${re}"
    cat $LIST_FILE
}

# ================== 菜单 ==================
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
