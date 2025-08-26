#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 配置 ==================
IMAGE="ghcr.io/nodepassproject/nodepassdash:latest"
CONTAINER="nodepassdash"
DEFAULT_PORT=3000
LOG_DIR="./logs"
PUBLIC_DIR="./public"
ADMIN_INFO_FILE="./admin_info.txt"

# ================== 功能函数 ==================
check_port() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        echo -e "${RED}端口 $port 已被占用，请选择其他端口${RESET}"
        return 1
    fi
    return 0
}

deploy() {
    while true; do
        echo -e "${GREEN}请输入要映射的端口 (默认 $DEFAULT_PORT):${RESET}"
        read input_port
        PORT=${input_port:-$DEFAULT_PORT}
        check_port $PORT && break
    done

    echo -e "${GREEN}🚀 拉取最新镜像...${RESET}"
    sudo docker pull $IMAGE

    echo -e "${GREEN}📂 创建必要目录...${RESET}"
    mkdir -p "$LOG_DIR" "$PUBLIC_DIR"
    chmod 777 "$LOG_DIR" "$PUBLIC_DIR"

    echo -e "${GREEN}⚡ 启动容器 (端口 $PORT)...${RESET}"
    sudo docker run -d \
        --name $CONTAINER \
        -p $PORT:3000 \
        -v "$(pwd)/logs:/app/logs" \
        -v "$(pwd)/public:/app/public" \
        $IMAGE \
        ./nodepassdash --port 3000

    echo -e "${GREEN}✅ 部署完成！获取管理员账户信息中...${RESET}"
    show_init_info $PORT
}

show_init_info() {
    PORT=${1:-$DEFAULT_PORT}
    echo "-------------------------------------------------"
    info=$(sudo docker logs $CONTAINER | grep -A 6 "系统初始化完成")
    echo -e "${GREEN}$info${RESET}"
    echo "-------------------------------------------------"
    echo -e "${GREEN}⚠️ 管理员账户信息已保存到 ${ADMIN_INFO_FILE}${RESET}"
    echo -e "${GREEN}端口号: $PORT\n$info${RESET}" > "$ADMIN_INFO_FILE"
}

reset_password() {
    echo -e "${GREEN}🔑 重置管理员密码中...${RESET}"
    sudo docker exec -it $CONTAINER ./nodepassdash --resetpwd
    echo -e "${GREEN}✅ 密码已重置，重启容器生效。${RESET}"
    sudo docker restart $CONTAINER
}

stop_container() {
    echo -e "${GREEN}🛑 停止容器...${RESET}"
    sudo docker stop $CONTAINER || echo -e "${GREEN}容器未运行${RESET}"
}

start_container() {
    echo -e "${GREEN}▶️ 启动容器...${RESET}"
    sudo docker start $CONTAINER || echo -e "${GREEN}容器不存在，请先部署${RESET}"
}

restart_container() {
    echo -e "${GREEN}🔄 重启容器...${RESET}"
    sudo docker restart $CONTAINER || echo -e "${GREEN}容器不存在，请先部署${RESET}"
}

uninstall_nodepass() {
    echo -e "${RED}⚠️ 正在卸载 NodePass，所有数据将被清理！${RESET}"

    echo -e "🛑 停止容器..."
    sudo docker stop $CONTAINER >/dev/null 2>&1 || true

    echo -e "❌ 删除容器..."
    sudo docker rm -f $CONTAINER >/dev/null 2>&1 || true

    echo -e "🖼️ 删除镜像..."
    sudo docker rmi -f $IMAGE >/dev/null 2>&1 || true

    echo -e "🗑️ 删除数据目录..."
    rm -rf "$LOG_DIR" "$PUBLIC_DIR" "$ADMIN_INFO_FILE"

    echo -e "${GREEN}✅ NodePass 已彻底卸载完成${RESET}"
    echo -e "${GREEN}按回车返回菜单...${RESET}"
    read -r
}

menu() {
    while true; do
        clear
        echo -e "${GREEN}================ NodePass Docker 管理 =================${RESET}"
        echo -e "${GREEN}1) 一键部署 NodePass（支持自定义端口）${RESET}"
        echo -e "${GREEN}2) 查看初始化信息${RESET}"
        echo -e "${GREEN}3) 重置管理员密码${RESET}"
        echo -e "${GREEN}4) 启动容器${RESET}"
        echo -e "${GREEN}5) 停止容器${RESET}"
        echo -e "${GREEN}6) 重启容器${RESET}"
        echo -e "${GREEN}7) 删除容器${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        echo -e "${GREEN}========================================================${RESET}"
        echo -ne "${GREEN}请选择操作 [0-7]: ${RESET}"
        read choice
        case $choice in
            1) deploy ;;
            2) show_init_info ;;
            3) reset_password ;;
            4) start_container ;;
            5) stop_container ;;
            6) restart_container ;;
            7) uninstall_nodepass;;
            0) exit 0 ;;
            *) echo -e "${GREEN}无效选项，请重新选择${RESET}"; sleep 1 ;;
        esac
        echo -e "${GREEN}按回车返回菜单...${RESET}"
        read
    done
}

menu 指令返回菜单，1部署完显示 访问地址IP加端口
