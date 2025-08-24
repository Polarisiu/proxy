#!/bin/bash

# ========== 颜色 ==========
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

# ========== 变量 ==========
NAME="mtproxy"
IMAGE="ellermister/mtproxy"
DEFAULT_PORT=8443
DEFAULT_DOMAIN="cloudflare.com"
DEFAULT_SECRET=$(openssl rand -hex 16)

# 检测公网 IP
get_public_ip() {
    curl -s https://api.ipify.org || echo "0.0.0.0"
}

# ========== 工具函数 ==========
pause() {
    echo -e "${yellow}按任意键返回菜单...${reset}"
    read -n 1
}

print_qr() {
    local url=$1
    if command -v qrencode &>/dev/null; then
        echo -e "\n${green}二维码:${reset}"
        echo "$url" | qrencode -t ANSIUTF8
    else
        echo -e "${yellow}⚠ 未安装 qrencode，无法生成二维码${reset}"
    fi
}

# ========== 功能 ==========
install_mtproxy() {
    read -p "请输入映射端口 (默认: ${DEFAULT_PORT}): " port
    port=${port:-$DEFAULT_PORT}

    read -p "请输入伪装域名 (默认: ${DEFAULT_DOMAIN}): " domain
    domain=${domain:-$DEFAULT_DOMAIN}

    read -p "请输入密钥(32位16进制，默认随机生成): " secret
    secret=${secret:-$DEFAULT_SECRET}

    read -p "白名单模式 [OFF/IP/IPSEG] (默认 OFF): " whitelist
    whitelist=${whitelist:-OFF}

    echo -e "\n${green}正在获取公网 IP...${reset}"
    public_ip=$(get_public_ip)
    echo -e "${green}检测到公网 IP：${public_ip}${reset}"
    read -p "是否使用该 IP？(直接回车确认，自定义请输入其他 IP): " custom_ip
    server_ip=${custom_ip:-$public_ip}

    docker rm -f $NAME &>/dev/null

    docker run -d \
        --name $NAME \
        --restart=always \
        -e domain="$domain" \
        -e secret="$secret" \
        -e ip_white_list="$whitelist" \
        -p ${port}:443 \
        $IMAGE

    sleep 3
    show_info "$server_ip" "$port" "$secret"
    pause
}

uninstall_mtproxy() {
    docker rm -f $NAME &>/dev/null && echo -e "${green}✅ 已卸载${reset}" || echo -e "${red}❌ 卸载失败${reset}"
    pause
}

show_logs() {
    if docker ps --format '{{.Names}}' | grep -q "^${NAME}\$"; then
        docker logs -f $NAME
    else
        echo -e "${red}❌ 容器未运行${reset}"
    fi
    pause
}

show_info() {
    local ip=$1
    local port=$2
    local secret=$3

    echo -e "\n${green}=== MTProxy 运行信息 ===${reset}\n"
    if docker ps --format '{{.Names}}' | grep -q "^${NAME}\$"; then
        docker logs $NAME 2>&1 | grep -A10 "TMProxy+TLS代理: 运行中"
        if [[ -n "$ip" && -n "$port" && -n "$secret" ]]; then
            # 生成可点击链接
            tgurl="https://t.me/proxy?server=${ip}&port=${port}&secret=ee${secret}79792e63636f2e75732e6b67"
            echo -e "\n${green}TG 一键链接:${reset} $tgurl"
            print_qr "$tgurl"
        fi
    else
        echo -e "${red}❌ 容器未运行${reset}"
    fi
}

modify_config() {
    echo -e "${green}当前配置:${reset}"
    docker inspect $NAME --format '{{.Config.Env}}' 2>/dev/null || echo "未找到容器"

    echo -e "\n${yellow}修改配置将重建容器${reset}\n"
    install_mtproxy
}

# ========== 菜单 ==========
while true; do
    clear
    echo -e "${green}===== MTProto Proxy 管理脚本 =====${reset}"
    echo -e "${green}1.${reset} 安装并启动代理"
    echo -e "${green}2.${reset} 卸载代理"
    echo -e "${green}3.${reset} 查看运行信息"
    echo -e "${green}4.${reset} 查看运行日志"
    echo -e "${green}5.${reset} 修改配置"
    echo -e "${green}0.${reset} 退出"
    echo -e "=================================\n"
    read -p "请输入选项: " choice
    case "$choice" in
        1) install_mtproxy ;;
        2) uninstall_mtproxy ;;
        3) 
            echo -e "\n${green}正在获取公网 IP...${reset}"
            public_ip=$(get_public_ip)
            read -p "请输入当前映射端口 (默认 ${DEFAULT_PORT}): " port
            port=${port:-$DEFAULT_PORT}
            read -p "请输入当前使用的 secret (必须): " secret
            show_info "$public_ip" "$port" "$secret"
            pause
            ;;
        4) show_logs ;;
        5) modify_config ;;
        0) exit 0 ;;
        *) echo -e "${red}❌ 无效选项${reset}" && sleep 1 ;;
    esac
done
