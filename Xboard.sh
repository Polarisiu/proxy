#!/bin/bash
# ========================================
# Xboard 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="Xboard"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

function menu() {
    clear
    echo -e "${GREEN}=== Xboard 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 重启${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 卸载(含数据)${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "请选择: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) restart_app ;;
        4) view_logs ;;
        5) uninstall_app ;;
        0) exit 0 ;;
        *) echo "无效选择"; sleep 1; menu ;;
    esac
}

function install_app() {
    mkdir -p "$APP_DIR"

    echo -e "${YELLOW}请输入管理员账号 (默认: admin@demo.com):${RESET}"
    read -r input_admin
    ADMIN_ACCOUNT=${input_admin:-admin@demo.com}

    cd "$APP_DIR" || exit
    if [ ! -d "$APP_DIR/.git" ]; then
        git clone -b compose --depth 1 https://github.com/cedar2025/Xboard "$APP_DIR"
    fi

    echo -e "${GREEN}=== 初始化数据库 ===${RESET}"
    docker compose run -it --rm \
        -e ENABLE_SQLITE=true \
        -e ENABLE_REDIS=true \
        -e ADMIN_ACCOUNT="$ADMIN_ACCOUNT" \
        web php artisan xboard:install

    echo -e "${GREEN}=== 启动服务 ===${RESET}"
    docker compose up -d

    echo -e "${GREEN}✅ Xboard 已安装并启动${RESET}"
    echo -e "${YELLOW}🌐 管理员账号: $ADMIN_ACCOUNT${RESET}"
    echo -e "${YELLOW}🌐 访问地址:http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    git pull
    docker compose pull
    docker compose run -it --rm web php artisan xboard:update
    docker compose up -d
    echo -e "${GREEN}✅ Xboard 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose down
    docker compose up -d
    echo -e "${GREEN}✅ Xboard 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker compose -f "$COMPOSE_FILE" logs -f
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Xboard 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

menu