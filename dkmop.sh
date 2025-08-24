#!/bin/bash
# MTProto Proxy 管理脚本 for Docker (更新版)

# 容器与镜像配置
NAME="mtproto-proxy"
IMAGE="telegrammessenger/proxy:latest"
VOLUME="proxy-config"

function install_proxy() {
    echo -e "\n=== 安装并启动 MTProto Proxy ===\n"
    read -p "请输入代理端口 (默认 443): " PORT
    PORT=${PORT:-443}

    # 如果已有容器先删除
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${NAME}\$"; then
        echo "⚠️ 已存在旧容器，先删除..."
        docker rm -f ${NAME}
    fi

    # 创建持久化卷
    docker volume create ${VOLUME} >/dev/null 2>&1

    # 启动代理
    docker run -d \
        --name=${NAME} \
        --restart=always \
        -v ${VOLUME}:/data \
        -p ${PORT}:${PORT}/tcp \
        -p ${PORT}:${PORT}/udp \
        ${IMAGE}

    echo "⏳ 等待 3 秒以生成 secret..."
    sleep 3

    # 获取密钥
    SECRET=$(docker exec ${NAME} cat /data/secret 2>/dev/null)
    if [[ -z "$SECRET" ]]; then
        echo "❌ 获取密钥失败，请检查容器是否正常运行。"
        return
    fi

    IP=$(curl -s ifconfig.me)

    echo -e "\n✅ 安装完成！代理信息如下："
    echo "服务器 IP: $IP"
    echo "端口     : $PORT"
    echo "密钥     : $SECRET"
    echo -e "\n👉 Telegram 链接："
    echo "tg://proxy?server=${IP}&port=${PORT}&secret=${SECRET}"
}

function uninstall_proxy() {
    echo -e "\n=== 卸载 MTProto Proxy ===\n"
    docker rm -f ${NAME} >/dev/null 2>&1
    docker volume rm -f ${VOLUME} >/dev/null 2>&1
    echo "✅ 已卸载并清理配置。"
}

function show_logs() {
    if ! docker ps --format '{{.Names}}' | grep -Eq "^${NAME}\$"; then
        echo "❌ 容器未运行，请先安装或启动代理。"
        return
    fi
    echo -e "\n=== MTProto Proxy 日志 ===\n"
    docker logs -f ${NAME}
}

function menu() {
    echo -e "\n===== MTProto Proxy 管理脚本 ====="
    echo "1. 安装并启动代理 (可自定义端口, 默认 443)"
    echo "2. 卸载代理"
    echo "3. 查看运行日志"
    echo "0. 退出"
    echo "================================="
    read -p "请输入选项: " choice
    case "$choice" in
        1) install_proxy ;;
        2) uninstall_proxy ;;
        3) show_logs ;;
        0) exit 0 ;;
        *) echo "❌ 无效输入" ;;
    esac
}

while true; do
    menu
done
