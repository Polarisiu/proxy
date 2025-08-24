#!/bin/bash

# ================== 颜色定义 ==================
green="\033[32m"
red="\033[31m"
re="\033[0m"

# ================== 变量定义 ==================
XRAY_BIN="/usr/local/bin/xray"
CONFIG_FILE="/usr/local/etc/xray/config.json"
LIST_FILE="/usr/local/etc/xray/node.txt"

# ================== 安装 ==================
install_vless() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${red}检测到已安装配置，请先卸载！${re}"
        return
    fi

    apk add -q --no-cache curl wget unzip >/dev/null 2>&1
    mkdir -p /usr/local/etc/xray

    echo -e "${green}下载并安装 Xray...${re}"
    wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -O /tmp/xray.zip
    unzip -qo /tmp/xray.zip -d /usr/local/bin
    chmod +x $XRAY_BIN

    UUID=$(cat /proc/sys/kernel/random/uuid)
    read -p "请输入端口 (默认 443): " input_port
    PORT=${input_port:-443}
    read -p "请输入 SNI 域名 (默认 www.yahoo.com): " input_sni
    SNI=${input_sni:-www.yahoo.com}

    KEYS=$($XRAY_BIN x25519)
    PrivateKey=$(echo "$KEYS" | awk '/Private/ {print $3}')
    PublicKey=$(echo "$KEYS" | awk '/Public/ {print $3}')
    shortid=$(openssl rand -hex 8)

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
        "realitySettings": {
          "show": false,
          "dest": "151.101.1.140:443",
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

    nohup $XRAY_BIN -c $CONFIG_FILE >/dev/null 2>&1 &
    sleep 2
    IP=$(curl -s ipv4.ip.sb)
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

    cat > $LIST_FILE <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF

    echo -e "${green}安装完成！节点信息如下:${re}"
    cat $LIST_FILE
}

# ================== 更换端口 ==================
change_port() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${red}未检测到配置文件，请先安装！${re}"
        return
    fi
    read -p "请输入新的端口: " new_port
    sed -i "s/\"port\": [0-9]\+/\"port\": $new_port/" $CONFIG_FILE
    restart_xray
    echo -e "${green}端口已修改，新节点信息:${re}"
    cat $LIST_FILE
}

# ================== 修改 SNI ==================
change_sni() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${red}未检测到配置文件，请先安装！${re}"
        return
    fi
    read -p "请输入新的 SNI 域名: " new_sni
    sed -i "s/\"serverNames\": \[\".*\"\]/\"serverNames\": [\"$new_sni\"]/" $CONFIG_FILE
    restart_xray
    echo -e "${green}SNI 已修改，新节点信息:${re}"
    cat $LIST_FILE
}

# ================== 修改 UUID ==================
change_uuid() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${red}未检测到配置文件，请先安装！${re}"
        return
    fi
    NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/\"id\": \".*\"/\"id\": \"$NEW_UUID\"/" $CONFIG_FILE
    restart_xray
    echo -e "${green}UUID 已修改，新节点信息:${re}"
    cat $LIST_FILE
}

# ================== 查看节点 ==================
show_link() {
    if [ -f "$LIST_FILE" ]; then
        echo -e "${green}当前节点信息:${re}"
        cat $LIST_FILE
    else
        echo -e "${red}未找到节点信息文件！${re}"
    fi
}

# ================== 卸载 ==================
uninstall() {
    pkill -f "$XRAY_BIN"
    rm -rf $XRAY_BIN /usr/local/etc/xray
    echo -e "${green}已卸载完成！${re}"
}

# ================== 重启函数 ==================
restart_xray() {
    pkill -f "$XRAY_BIN"
    nohup $XRAY_BIN -c $CONFIG_FILE >/dev/null 2>&1 &
    sleep 2

    UUID=$(grep -oP '(?<="id": ")[^"]*' $CONFIG_FILE)
    PORT=$(grep -oP '(?<="port": )\d+' $CONFIG_FILE)
    SNI=$(grep -oP '(?<="serverNames\": \[")[^"]*' $CONFIG_FILE)
    PublicKey=$(grep -A1 'publicKey' $CONFIG_FILE | tail -n1 | awk -F'"' '{print $4}')
    shortid=$(grep -oP '(?<="shortIds\": \[")[^"]*' $CONFIG_FILE)

    IP=$(curl -s ipv4.ip.sb)
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

    cat > $LIST_FILE <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF
}

# ================== 菜单 ==================
show_menu() {
    clear
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}  VLESS Reality 管理脚本${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}1) 安装${re}"
    echo -e "${green}2) 更换端口${re}"
    echo -e "${green}3) 修改 SNI 域名${re}"
    echo -e "${green}4) 修改 UUID (密码)${re}"
    echo -e "${green}5) 查看节点链接${re}"
    echo -e "${green}6) 卸载${re}"
    echo -e "${green}0) 退出${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    read -p "请输入选项: " num
    case "$num" in
        1) install_vless ;;
        2) change_port ;;
        3) change_sni ;;
        4) change_uuid ;;
        5) show_link ;;
        6) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项！${re}" ;;
    esac
    read -p "按回车键返回菜单..." enter
    show_menu
}

# ================== 启动菜单 ==================
show_menu
