#!/bin/bash
# ========================================
# FRP-Panel Server (子节点) 一键管理脚本
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
RED="\033[31m"
APP_NAME="frp-panel-server"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== FRP-Panel Server 管理菜单 ===${RESET}"
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
    mkdir -p "$APP_DIR"

    read -p "请输入全局密钥 ( Master 生成): " secret
    read -p "请输入节点 ID [默认: node1]: " input_id
    NODE_ID=${input_id:-node1}
    read -p "请输入 Master API 地址 [例如: http://frpp.example.com:9000]: " input_api
    API_URL=${input_api:-http://frpp.example.com:9000}
    read -p "请输入 Master RPC 地址 [例如: grpc://frpp-rpc.example.com:9001]: " input_rpc
    RPC_URL=${input_rpc:-grpc://frpp-rpc.example.com:9001}

    cat > "$CONFIG_FILE" <<EOF
SECRET=$secret
NODE_ID=$NODE_ID
API_URL=$API_URL
RPC_URL=$RPC_URL
EOF

    cat > "$COMPOSE_FILE" <<EOF
services:
  frp-panel-server:
    image: vaalacat/frp-panel:latest
    container_name: frp-panel-server
    network_mode: host
    restart: unless-stopped
    command: server -s $secret -i $NODE_ID --api-url $API_URL --rpc-url $RPC_URL
EOF

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ FRP-Panel Server 已启动${RESET}"
    echo -e "${GREEN}🆔 节点ID: $NODE_ID${RESET}"
    echo -e "${GREEN}🔑 密钥: $secret${RESET}"
    echo -e "${GREEN}🌐 Master API: $API_URL${RESET}"
    echo -e "${GREEN}🌐 Master RPC: $RPC_URL${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ FRP-Panel Server 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ FRP-Panel Server 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f frp-panel-server
    read -p "按回车返回菜单..."
    menu
}

menu
