#!/bin/sh
# MTProto Proxy 管理脚本 (Alpine + Docker)

NAME="mtproto"
IMAGE="telegrammessenger/proxy:latest"

# 获取公网 IP
get_ip() {
    curl -s https://api.ipify.org || curl -s ifconfig.me
}

# 安装并启动代理
install_proxy() {
    echo "=== 安装并启动 MTProto Proxy ==="
    read -p "请输入外部端口 (默认 8443): " PORT
    PORT=${PORT:-8443}

    # 删除旧容器
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${NAME}\$"; then
        echo "⚠️ 检测到旧容器，正在删除..."
        docker rm -f ${NAME} >/dev/null 2>&1
    fi

    # 拉取镜像
    docker pull $IMAGE

    # 启动容器
    docker run -d --name ${NAME} \
        --restart=always \
        -p ${PORT}:443 \
        $IMAGE

    # 生成 Secret
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)

    # 应用 Secret
    docker exec -it ${NAME} mtproto-proxy -p 443 -H 80 -S $SECRET >/dev/null 2>&1 &

    # 获取 IP
    IP=$(get_ip)

    echo
    echo "✅ 部署完成！代理信息如下："
    echo "服务器 IP : $IP"
    echo "端口       : $PORT"
    echo "Secret     : $SECRET"
    echo
    echo "👉 Telegram 链接："
    echo "tg://proxy?server=$IP&port=$PORT&secret=$SECRET"
    echo
}

# 卸载代理
uninstall_proxy() {
    echo "=== 卸载 MTProto Proxy ==="
    docker rm -f ${NAME} >/dev/null 2>&1
    echo "✅ 已卸载代理容器。"
}

# 查看日志
show_logs() {
    if ! docker ps --format '{{.Names}}' | grep -Eq "^${NAME}\$"; then
        echo "❌ 容器未运行，请先安装。"
        return
    fi
    echo "=== MTProto Proxy 日志 (最近50行) ==="
    docker logs --tail=50 -f ${NAME}
}

# 菜单
menu() {
    while true; do
        echo "===== MTProto Proxy 管理菜单 ====="
        echo "1) 安装并启动代理"
        echo "2) 卸载代理"
        echo "3) 查看运行日志"
        echo "0) 退出"
        echo "================================="
        read -p "请输入选项: " choice
        case "$choice" in
            1) install_proxy ;;
            2) uninstall_proxy ;;
            3) show_logs ;;
            0) exit 0 ;;
            *) echo "❌ 无效输入，请重试。" ;;
        esac
    done
}

menu
