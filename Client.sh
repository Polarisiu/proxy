#!/bin/bash
# ==========================================
# FRP-PanelClient 管理脚本
# 支持部署 / 卸载 / 更新 / 查看日志
# 操作完成后自动返回菜单，整个菜单和标题字体绿色
# ==========================================

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="/opt/frpp-client"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"
CONTAINER_NAME="frp-panel-client"

menu() {
    clear
    echo -e "${GREEN}=== FRP-Panel Client管理菜单 ===${NC}"
    echo -e "${GREEN}1) FRP-Panel Client部署${NC}"
    echo -e "${GREEN}2) FRP-Panel Client卸载${NC}"
    echo -e "${GREEN}3) FRP-Panel Client更新镜像${NC}"
    echo -e "${GREEN}4) FRP-Panel Client查看日志${NC}"
    echo -e "${GREEN}0) 退出${NC}"
    echo -ne "${GREEN}请输入编号:${NC} "
    read choice
    case $choice in
        1) deploy ;;
        2) uninstall ;;
        3) update ;;
        4) logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}输入错误${NC}"; sleep 1; menu ;;
    esac
}

deploy() {
    echo -e "${GREEN}=== FRP-PanelClient 部署 ===${NC}"
    read -p "请输入 Server Token: " SERVER_TOKEN
    read -p "请输入 Client 名称: " CLIENT_NAME
    read -p "请输入 API URL (例如 https://frpp.example.com:443): " API_URL
    read -p "请输入 RPC URL (例如 wss://frpp.example.com:443): " RPC_URL

    mkdir -p "$BASE_DIR"

    cat > "$COMPOSE_FILE" <<EOF
version: '3'
services:
  frp-panel-client:
    image: vaalacat/frp-panel
    container_name: $CONTAINER_NAME
    network_mode: host
    restart: unless-stopped
    command: client -s $SERVER_TOKEN -i $CLIENT_NAME --api-url $API_URL --rpc-url $RPC_URL
EOF

    cd "$BASE_DIR"
    docker-compose up -d
    echo -e "${GREEN}✅ FRP-PanelClient 已启动${NC}"
    read -p "按任意键返回菜单..." -n1 -s
    menu
}

uninstall() {
    echo -e "${GREEN}=== FRP-PanelClient 卸载 ===${NC}"
    if [ -f "$COMPOSE_FILE" ]; then
        cd "$BASE_DIR"
        docker-compose down
        rm -rf "$BASE_DIR"
        echo -e "${GREEN}✅ FRP-PanelClient 已卸载${NC}"
    else
        echo -e "${RED}FRP-PanelClient 未部署${NC}"
    fi
    read -p "按任意键返回菜单..." -n1 -s
    menu
}

update() {
    echo -e "${GREEN}=== FRP-PanelClient 更新镜像 ===${NC}"
    docker pull vaalacat/frp-panel
    if [ -f "$COMPOSE_FILE" ]; then
        cd "$BASE_DIR"
        docker-compose up -d
        echo -e "${GREEN}✅ FRP-PanelClient 已更新并重启${NC}"
    else
        echo -e "${RED}FRP-PanelClient 未部署，无法重启${NC}"
    fi
    read -p "按任意键返回菜单..." -n1 -s
    menu
}

logs() {
    echo -e "${GREEN}=== FRP-PanelClient 日志查看 ===${NC}"
    docker logs -f $CONTAINER_NAME
    read -p "按任意键返回菜单..." -n1 -s
    menu
}

menu
