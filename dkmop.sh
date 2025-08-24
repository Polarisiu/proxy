#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ================== 配置 ==================
NAME="mtproxy"
DOMAIN="duka.cco.us.kg"

# ================== 工具函数 ==================
get_ip() {
    curl -s ipv4.icanhazip.com || hostname -I | awk '{print $1}'
}

random_port() {
    shuf -i 20000-65000 -n 1
}

# ================== 安装并启动代理 ==================
install_proxy() {
    PORT=$(random_port)
    docker rm -f $NAME >/dev/null 2>&1
    docker run -d --name=$NAME \
        -p ${PORT}:8443 \
        cmliu/mtproxy \
        mtproto-proxy -u nobody -p 8888 -H 8443 \
        -S $(head -c 16 /dev/urandom | xxd -ps) \
        --aes-pwd proxy-secret proxy-multi.conf -M 4 \
        --domain $DOMAIN --nat-info "$(hostname -i):$(get_ip)" --ipv6

    sleep 3
    show_info
}

# ================== 显示代理信息 ==================
show_info() {
    IP=$(get_ip)
    SECRET=$(docker logs ${NAME} 2>&1 | grep "MTProxy Secret" | awk '{print $NF}' | tail -n1)
    PORT=$(docker ps --filter "name=$NAME" --format "{{.Ports}}" | grep -oP ':(\d+)->8443' | cut -d: -f2 | cut -d- -f1)

    echo -e "\n${GREEN}✅ 代理信息如下：${RESET}"
    echo "服务器 IP : $IP"
    echo "端口       : $PORT"
    echo "Secret     : $SECRET"
    echo "Domain     : $DOMAIN"
    echo
    echo "👉 Telegram 链接："
    echo "tg://proxy?server=$IP&port=$PORT&secret=$SECRET"
}

# ================== 卸载代理 ==================
uninstall_proxy() {
    docker rm -f $NAME
    echo -e "${RED}❌ 已卸载 MTProto Proxy${RESET}"
}

# ================== 查看运行日志 ==================
view_logs() {
    docker logs --tail=50 -f $NAME
}

# ================== 修改配置并重启 ==================
modify_config() {
    docker restart $NAME
    sleep 3
    show_info
}

# ================== 菜单 ==================
while true; do
    echo -e "\n===== MTProto Proxy 管理脚本 ====="
    echo "1. 安装并启动代理"
    echo "2. 卸载代理"
    echo "3. 查看运行日志"
    echo "4. 修改配置并重启容器"
    echo "0. 退出"
    echo "================================="
    read -p "请输入选项: " choice

    case $choice in
        1) install_proxy ;;
        2) uninstall_proxy ;;
        3) view_logs ;;
        4) modify_config ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项，请重试！${RESET}" ;;
    esac
done
