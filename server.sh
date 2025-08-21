#!/bin/bash
# ==========================================
# 一键管理 FRP-Panel Server (Docker)
# 功能: 安装/启动 | 卸载 | 更新 | 查看日志
# 每次操作完成后返回菜单，菜单字体绿色
# ==========================================

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="$(pwd)"
COMPOSE_FILE="$BASE_DIR/docker-compose.yaml"
CONTAINER_NAME="frp-panel-server"

show_menu() {
    echo -e "${GREEN}=== FRP-Panel Server 部署 ===${NC}"
    echo -e "${GREEN}1) 安装/启动 Server${NC}"
    echo -e "${GREEN}2) 卸载 Server${NC}"
    echo -e "${GREEN}3) 更新 Server${NC}"
    echo -e "${GREEN}4) 查看 Server 日志${NC}"
    echo -e "${GREEN}5) 退出${NC}"
    read -p "$(echo -e ${GREEN}请输入选项 [1-5]: ${NC})" choice
}

install_or_start() {
    echo -e "${GREEN}=== 安装/启动 FRP-Panel Server ===${NC}"
    read -p "请输入全局密钥 (-s) [abc123]: " APP_SECRET
    APP_SECRET=${APP_SECRET:-abc123}

    read -p "请输入 Server 实例名 (-i) [user.s.server1]: " INSTANCE_NAME
    INSTANCE_NAME=${INSTANCE_NAME:-user.s.server1}

    read -p "请输入 API URL [http://frpp.example.com:9000]: " API_URL
    API_URL=${API_URL:-http://frpp.example.com:9000}

    read -p "请输入 RPC URL [grpc://frpp-rpc.example.com:9001]: " RPC_URL
    RPC_URL=${RPC_URL:-grpc://frpp-rpc.example.com:9001}

    cat > "$COMPOSE_FILE" <<EOF
version: '3'
services:
  frp-panel-server:
    image: vaalacat/frp-panel
    container_name: $CONTAINER_NAME
    network_mode: host
    restart: unless-stopped
    command: server -s $APP_SECRET -i $INSTANCE_NAME --api-url $API_URL --rpc-url $RPC_URL
EOF

    echo -e "${GREEN}docker-compose.yaml 已生成:${NC}"
    cat "$COMPOSE_FILE"

    echo -e "${GREEN}正在启动 FRP-Panel Server...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✅ Server 启动完成，容器名: $CONTAINER_NAME${NC}"
    read -p "按回车键返回主菜单..." 
}

uninstall() {
    echo -e "${GREEN}=== 卸载 FRP-Panel Server ===${NC}"
    docker-compose down
    rm -f "$COMPOSE_FILE"
    echo -e "${GREEN}✅ Server 卸载完成${NC}"
    read -p "按回车键返回主菜单..." 
}

update() {
    echo -e "${GREEN}=== 更新 FRP-Panel Server 镜像 ===${NC}"
    docker pull vaalacat/frp-panel
    docker-compose up -d
    echo -e "${GREEN}✅ Server 更新完成${NC}"
    read -p "按回车键返回主菜单..." 
}

show_logs() {
    echo -e "${GREEN}=== 查看 FRP-Panel Server 日志 (Ctrl+C 退出) ===${NC}"
    docker logs -f $CONTAINER_NAME
    echo -e "${GREEN}已退出日志查看${NC}"
    read -p "按回车键返回主菜单..." 
}

while true; do
    show_menu
    case "$choice" in
        1) install_or_start ;;
        2) uninstall ;;
        3) update ;;
        4) show_logs ;;
        5) exit 0 ;;
        *) echo -e "${GREEN}无效选项${NC}" ;;
    esac
done
