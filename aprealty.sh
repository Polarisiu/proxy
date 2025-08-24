#!/bin/sh

green="\033[32m"
red="\033[31m"
re="\033[0m"

CONTAINER_NAME="xray"
CONFIG_DIR="/usr/local/etc/xray"
CONFIG_FILE="$CONFIG_DIR/config.json"
LIST_FILE="$CONFIG_DIR/node.txt"

# 安装 Docker
install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${green}安装 Docker...${re}"
        apk add --no-cache docker bash curl unzip iproute2 openssl >/dev/null 2>&1
        rc-update add docker boot
        service docker start
    else
        echo -e "${green}Docker 已安装${re}"
    fi
}

# 生成 x25519 密钥
generate_keys() {
    TEMP_DIR=$(mktemp -d)
    docker run --rm --privileged -v $TEMP_DIR:/tmp teddysun/xray x25519 > $TEMP_DIR/keys.txt
    PrivateKey=$(sed -n 's/.*Private Key: //p' $TEMP_DIR/keys.txt)
    PublicKey=$(sed -n 's/.*Public Key: //p' $TEMP_DIR/keys.txt)
    rm -rf $TEMP_DIR
}

# 写配置文件
write_config() {
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
}

# 设置配置
setup_config() {
    mkdir -p "$CONFIG_DIR"
    read -p "请输入端口 (默认 443): " input_port
    PORT=${input_port:-443}
    read -p "请输入 SNI 域名 (默认 www.yahoo.com): " input_sni
    SNI=${input_sni:-www.yahoo.com}
    UUID=$(cat /proc/sys/kernel/random/uuid)
    shortid=$(openssl rand -hex 8)
    generate_keys
    write_config
}

# 生成节点信息
generate_node() {
    IP=$(curl -s ipv4.ip.sb)
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')
    cat > $LIST_FILE <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF
}

# 启动 Xray Docker
start_xray() {
    docker rm -f $CONTAINER_NAME >/dev/null 2>&1
    docker run -d --name $CONTAINER_NAME --privileged -p $PORT:$PORT \
      -v $CONFIG_FILE:/etc/xray/config.json teddysun/xray
    sleep 2
    echo -e "${green}Xray Docker 已启动${re}"
    generate_node
    cat $LIST_FILE
}

# 重启 Xray Docker
restart_xray() {
    docker restart $CONTAINER_NAME
    sleep 2
    echo -e "${green}Xray Docker 已重启${re}"
    cat $LIST_FILE
}

# 停止 Xray Docker
stop_xray() {
    docker stop $CONTAINER_NAME >/dev/null 2>&1
    echo -e "${green}Xray Docker 已停止${re}"
}

# 修改端口/SNI 并重启
modify_port_sni() {
    read -p "请输入新端口 (当前 $PORT): " new_port
    PORT=${new_port:-$PORT}
    read -p "请输入新 SNI (当前 $SNI): " new_sni
    SNI=${new_sni:-$SNI}
    write_config
    restart_xray
}

# 卸载 Xray Docker
uninstall() {
    docker rm -f $CONTAINER_NAME >/dev/null 2>&1
    rm -rf $CONFIG_DIR
    echo -e "${green}卸载完成${re}"
}

# 菜单
show_menu() {
    clear
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}      Xray Reality Docker 管理脚本${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}1) 安装并启动 Xray Docker${re}"
    echo -e "${green}2) 修改端口/SNI 并重启${re}"
    echo -e "${green}3) 重启 Xray Docker${re}"
    echo -e "${green}4) 停止 Xray Docker${re}"
    echo -e "${green}5) 查看节点信息${re}"
    echo -e "${green}6) 卸载 Xray Docker${re}"
    echo -e "${green}0) 退出${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    read -p "请输入选项: " num
    case "$num" in
        1) install_docker; setup_config; start_xray ;;
        2) modify_port_sni ;;
        3) restart_xray ;;
        4) stop_xray ;;
        5) cat $LIST_FILE ;;
        6) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项！${re}" ;;
    esac
    read -p "按回车返回菜单..." enter
    show_menu
}

show_menu
