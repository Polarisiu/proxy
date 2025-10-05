#!/bin/bash
# ========================================
# 3X-UI 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
RED="\033[31m"
APP_NAME="3xui"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== 3X-UI 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
    esac
}

function install_app() {

    mkdir -p "$APP_DIR/db" "$APP_DIR/cert"

    cat > "$COMPOSE_FILE" <<EOF
services:
  xui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: xui
    restart: unless-stopped
    network_mode: host
    volumes:
      - $APP_DIR/db:/etc/x-ui/
      - $APP_DIR/cert:/root/cert/
    environment:
      - XRAY_VMESS_AEAD_FORCED=false
EOF

    echo "PORT=$PORT" > "$CONFIG_FILE"

    cd "$APP_DIR"
    docker compose up -d

    # 获取本机公网 IP
    get_ip() {
        curl -s ifconfig.me || curl -s ip.sb || hostname -I | awk '{print $1}' || echo "127.0.0.1"
    }

    echo -e "${GREEN}✅ 3X-UI 已启动${RESET}"
    echo -e "${GREEN}🌐 Web UI 地址: http://$(get_ip):2053${RESET}"
    echo -e "${GREEN}📂 证书位置: $APP_DIR/cert${RESET}"
    echo -e "${GREEN}初始账号/密码: admin/admin${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    source "$CONFIG_FILE"
    echo -e "${GREEN}✅ 3X-UI 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ 3X-UI 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f xui
    read -p "按回车返回菜单..."
    menu
}

menu
