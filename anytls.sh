#!/bin/bash

# anytls 安装/卸载管理脚本
# 功能：安装 anytls、修改端口或卸载
# 支持架构：amd64 (x86_64)、arm64 (aarch64)、armv7 (armv7l)

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

SERVICE_NAME="anytls"
BINARY_NAME="anytls-server"
BINARY_DIR="/usr/local/bin"

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "必须使用 root 或 sudo 运行！"
    exit 1
fi

# 安装必要工具
function install_dependencies() {
    echo "[初始化] 安装必要依赖（wget, curl, unzip, openssl）..."
    apt update -y >/dev/null 2>&1
    for dep in wget curl unzip openssl; do
        if ! command -v $dep &>/dev/null; then
            echo "正在安装 $dep..."
            apt install -y $dep || { echo "请手动安装 $dep"; exit 1; }
        fi
    done
}

install_dependencies

# 自动检测架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)  BINARY_ARCH="amd64" ;;
    aarch64) BINARY_ARCH="arm64" ;;
    armv7l)  BINARY_ARCH="armv7" ;;
    *)       echo "不支持的架构: $ARCH"; exit 1 ;;
esac

DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/download/v0.0.8/anytls_0.0.8_linux_${BINARY_ARCH}.zip"
ZIP_FILE="/tmp/anytls_0.0.8_linux_${BINARY_ARCH}.zip"

# 获取公网 IP
get_ip() {
    local ip
    ip=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d'/' -f1 | head -n1)
    [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -n1)
    [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 3 ifconfig.me 2>/dev/null || curl -4 -s --connect-timeout 3 icanhazip.com 2>/dev/null)
    [ -z "$ip" ] && read -p "请输入服务器IP: " ip
    echo "$ip"
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}-------------------------------------${RESET}"
    echo -e "${GREEN} anytls 服务管理脚本 (${BINARY_ARCH}架构) ${RESET}"
    echo -e "${GREEN}-------------------------------------${RESET}"
    echo -e "${GREEN}1. 安装 anytls${RESET}"
    echo -e "${GREEN}2. 卸载 anytls${RESET}"
    echo -e "${GREEN}3. 修改端口${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}-------------------------------------${RESET}"
    read -p "请输入选项 [0-3]: " choice
    case $choice in
        1) install_anytls ;;
        2) uninstall_anytls ;;
        3) modify_port ;;
        0) exit 0 ;;
        *) echo -e "${YELLOW}无效选项！${RESET}" && sleep 1 && show_menu ;;
    esac
}

# 安装 anytls
install_anytls() {
    read -p "请输入监听端口 [默认8443]: " PORT
    PORT=${PORT:-8443}

    # 下载 anytls
    echo "[1/5] 下载 anytls..."
    wget "$DOWNLOAD_URL" -O "$ZIP_FILE" || { echo "下载失败！"; exit 1; }

    # 解压
    echo "[2/5] 解压文件..."
    unzip -o "$ZIP_FILE" -d "$BINARY_DIR" || { echo "解压失败！"; exit 1; }
    chmod +x "$BINARY_DIR/$BINARY_NAME"
    rm -f "$ZIP_FILE"

    # 密码输入
    read -s -p "设置密码（留空随机生成）: " PASSWORD
    echo
    [ -z "$PASSWORD" ] && PASSWORD=$(openssl rand -base64 12)

    # 配置 systemd
    echo "[3/5] 配置 systemd 服务..."
    cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=anytls Service
After=network.target

[Service]
ExecStart=$BINARY_DIR/$BINARY_NAME -l 0.0.0.0:$PORT -p $PASSWORD
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    echo "[4/5] 启动服务..."
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME

    SERVER_IP=$(get_ip)

    # 安装完成信息
    echo -e "\n${GREEN}√ 安装完成！${RESET}"
    echo -e "${GREEN}√ 架构: ${BINARY_ARCH}${RESET}"
    echo -e "${GREEN}√ 服务: $SERVICE_NAME${RESET}"
    echo -e "${GREEN}√ 端口: $PORT${RESET}"
    echo -e "${GREEN}√ 密码: $PASSWORD${RESET}"

    echo -e "\n${YELLOW}管理命令:${RESET}"
    echo "  启动: systemctl start $SERVICE_NAME"
    echo "  停止: systemctl stop $SERVICE_NAME"
    echo "  重启: systemctl restart $SERVICE_NAME"
    echo "  状态: systemctl status $SERVICE_NAME"

    echo -e "\n${CYAN}\033[1m〓 NekoBox连接信息 〓${RESET}"
    echo -e "\033[30;43m\033[1m anytls://$PASSWORD@$SERVER_IP:$PORT/?insecure=1 \033[0m"
    echo -e "${YELLOW}\033[1m请妥善保管此连接信息！${RESET}"
}

# 卸载
uninstall_anytls() {
    read -p "确定要卸载 anytls 吗？(y/N): " confirm
    [[ $confirm != [yY] ]] && echo "取消卸载" && return

    echo "正在卸载 anytls..."
    systemctl stop $SERVICE_NAME 2>/dev/null
    systemctl disable $SERVICE_NAME 2>/dev/null
    [ -f "$BINARY_DIR/$BINARY_NAME" ] && rm -f "$BINARY_DIR/$BINARY_NAME"
    [ -f "/etc/systemd/system/$SERVICE_NAME.service" ] && rm -f "/etc/systemd/system/$SERVICE_NAME.service"
    systemctl daemon-reload
    echo -e "${GREEN}anytls 已完全卸载！${RESET}"
}

# 修改端口
modify_port() {
    if [ ! -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        echo -e "${YELLOW}未检测到已安装的 anytls 服务${RESET}"
        sleep 2
        return
    fi
    read -p "请输入新端口: " NEW_PORT
    [ -z "$NEW_PORT" ] && echo "端口不能为空" && return
    sed -i -r "s/-l 0\.0\.0\.0:[0-9]+/-l 0.0.0.0:$NEW_PORT/" /etc/systemd/system/$SERVICE_NAME.service
    systemctl daemon-reload
    systemctl restart $SERVICE_NAME
    echo -e "${GREEN}端口已修改为 $NEW_PORT 并重启服务${RESET}"
}

# 循环菜单
while true; do
    show_menu
done
