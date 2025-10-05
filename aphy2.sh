#!/bin/bash
# =========================
# Hysteria v2 管理脚本（Alpine）
# =========================

# =========================
# 颜色定义
# =========================
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

HYSTERIA_BIN="/usr/local/bin/hysteria"
CONFIG_FILE="/etc/hysteria/config.yaml"
INIT_SCRIPT="/etc/init.d/hysteria"
PASS_FILE="/root/hysteria_pass.txt"
SNI_FILE="/root/hysteria_sni.txt"

# ===================== 工具函数 =====================
detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *) echo "unsupported" ;;
    esac
}

generate_password() {
    head -c 18 /dev/urandom | base64
}

download_hysteria() {
    local arch
    arch=$(detect_arch)
    if [ "$arch" = "unsupported" ]; then
        echo -e "${RED}不支持的架构: $(uname -m)${RESET}"
        return 1
    fi
    wget -O "$HYSTERIA_BIN" "https://download.hysteria.network/app/latest/hysteria-linux-$arch" --no-check-certificate
    chmod +x "$HYSTERIA_BIN"
}

generate_cert() {
    local domain="$1"
    mkdir -p /etc/hysteria
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/hysteria/server.key \
        -out /etc/hysteria/server.crt \
        -subj "/CN=$domain" -days 3650
}

write_config() {
    local port="$1"
    local password="$2"
    local domain="$3"
    echo "$domain" > "$SNI_FILE"   # 保存 SNI 以便生成客户端链接
    cat > "$CONFIG_FILE" << EOF
# SNI=$domain
listen: :$port

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $password

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF
}

write_init() {
    cat > "$INIT_SCRIPT" << EOF
#!/sbin/openrc-run
description="Hysteria proxy server"

name="hysteria"
command="$HYSTERIA_BIN"
command_args="server --config $CONFIG_FILE"
pidfile="/var/run/\${name}.pid"
command_background="yes"

depend() {
    need networking
}
EOF
    chmod +x "$INIT_SCRIPT"
    rc-update add hysteria
}

# ===================== 客户端链接 =====================
generate_client_link() {
    if [ -f "$PASS_FILE" ]; then
        SERVER_IP=$(curl -s https://api.ipify.org)
        PORT=$(grep '^listen:' "$CONFIG_FILE" | sed 's/listen: *://')
        PASSWORD=$(cat "$PASS_FILE")
        # URL encode 密码
        PASSWORD_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PASSWORD'))")
        # 从安装保存的 SNI 文件读取
        if [ -f "$SNI_FILE" ]; then
            SNI=$(cat "$SNI_FILE")
        else
            SNI="bing.com"
        fi

        LINK="hysteria2://${PASSWORD_ENCODED}@${SERVER_IP}:${PORT}?sni=${SNI}&alpn=h3&insecure=1#Hysteria"

        echo -e "${GREEN}------------------------------------------------------------------------${RESET}"
        echo -e "${GREEN}客户端链接 (可直接复制到客户端)：${RESET}"
        echo -e "${GREEN}$LINK${RESET}"
        echo -e "${GREEN}------------------------------------------------------------------------${RESET}"
    else
        echo -e "${RED}未找到密码文件，请确认 Hysteria 是否已安装${RESET}"
    fi
    read -p "按回车返回菜单..."
}

# ===================== 功能函数 =====================
install_hysteria() {
    read -p "请输入监听端口 (默认 40443): " H_PORT
    H_PORT=${H_PORT:-40443}
    read -p "请输入SNI/域名 (默认 bing.com): " H_DOMAIN
    H_DOMAIN=${H_DOMAIN:-bing.com}

    apk add --no-cache wget curl openssh openssl openrc bash

    GENPASS=$(generate_password)
    echo "$GENPASS" > "$PASS_FILE"

    download_hysteria
    generate_cert "$H_DOMAIN"
    write_config "$H_PORT" "$GENPASS" "$H_DOMAIN"
    write_init

    service hysteria start

    echo -e "${GREEN}Hysteria v2 安装完成${RESET}"
    echo -e "${GREEN}监听端口: $H_PORT${RESET}"
    echo -e "${GREEN}密码已保存到: $PASS_FILE${RESET}"
    echo -e "${GREEN}SNI/域名: $H_DOMAIN${RESET}"
    echo -e "${GREEN}配置文件: $CONFIG_FILE${RESET}"
    echo -e "${GREEN}服务已设置开机自启${RESET}"

    generate_client_link
}

show_status() {
    service hysteria status
    read -p "按回车返回菜单..."
}

start_service() {
    service hysteria start
    echo -e "${GREEN}服务已启动${RESET}"
    read -p "按回车返回菜单..."
}

stop_service() {
    service hysteria stop
    echo -e "${GREEN}服务已停止${RESET}"
    read -p "按回车返回菜单..."
}

restart_service() {
    service hysteria restart
    echo -e "${GREEN}服务已重启${RESET}"
    read -p "按回车返回菜单..."
}

change_port() {
    read -p "请输入新端口: " NEW_PORT
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s/^listen: .*/listen: :$NEW_PORT/" "$CONFIG_FILE"
        restart_service
        echo -e "${GREEN}端口已修改为 $NEW_PORT 并重启服务${RESET}"
        generate_client_link
    else
        echo -e "${RED}Hysteria 未安装${RESET}"
        read -p "按回车返回菜单..."
    fi
}

change_password() {
    NEW_PASS=$(generate_password)
    echo "$NEW_PASS" > "$PASS_FILE"
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s/^  password: .*/  password: $NEW_PASS/" "$CONFIG_FILE"
        restart_service
        echo -e "${GREEN}密码已修改并重启服务${RESET}"
        generate_client_link
    else
        echo -e "${RED}Hysteria 未安装${RESET}"
        read -p "按回车返回菜单..."
    fi
}

uninstall_hysteria() {
    stop_service
    rc-update del hysteria
    rm -f "$HYSTERIA_BIN" "$CONFIG_FILE" "$INIT_SCRIPT" "$PASS_FILE" "$SNI_FILE"
    echo -e "${GREEN}Hysteria 已卸载${RESET}"
    read -p "按回车返回菜单..."
}

# ===================== 菜单 =====================
while true; do
    clear
    echo -e "${GREEN}==== Hysteria v2 管理脚本 =====${RESET}"
    echo -e "${GREEN}1) 安装${RESET}"
    echo -e "${GREEN}2) 查看状态${RESET}"
    echo -e "${GREEN}3) 启动服务${RESET}"
    echo -e "${GREEN}4) 停止服务${RESET}"
    echo -e "${GREEN}5) 重启服务${RESET}"
    echo -e "${GREEN}6) 修改端口${RESET}"
    echo -e "${GREEN}7) 修改密码${RESET}"
    echo -e "${GREEN}8) 卸载${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case "$choice" in
        1) install_hysteria ;;
        2) show_status ;;
        3) start_service ;;
        4) stop_service ;;
        5) restart_service ;;
        6) change_port ;;
        7) change_password ;;
        8) uninstall_hysteria ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}" ;;
    esac
done
