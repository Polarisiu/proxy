#!/bin/bash

# ========== 颜色 ==========
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
re="\033[0m"

# ========== 安装 MTProxy ==========
install_mtproxy() {
    echo -e "${green}请输入代理端口 (默认 443):${re}"
    read -r port
    [[ -z "$port" ]] && port=443

    echo -e "${green}请输入自定义密钥 (留空则随机生成):${re}"
    read -r secret
    if [[ -z "$secret" ]]; then
        secret=$(openssl rand -hex 16)
    fi

    echo -e "${green}选择白名单模式:${re}"
    echo " 1) OFF  (关闭白名单)"
    echo " 2) IP   (开启 IP 白名单)"
    echo " 3) IPSEG(开启 IP 段白名单)"
    read -r mode
    case $mode in
        2) ip_white_list="IP" ;;
        3) ip_white_list="IPSEG" ;;
        *) ip_white_list="OFF" ;;
    esac

    docker rm -f mtproxy >/dev/null 2>&1 || true

    echo -e "${yellow}正在安装并启动 MTProxy...${re}"
    docker run -d --name mtproxy --restart=always \
      -e domain="cloudflare.com" \
      -e secret="$secret" \
      -e ip_white_list="$ip_white_list" \
      -p ${port}:${port} \
      ellermister/mtproxy

    sleep 3
    show_info "$port" "$secret"
}

# ========== 显示代理信息 ==========
show_info() {
    port=$1
    secret=$2
    ip=$(curl -s ifconfig.me)

    echo -e "${green}✅ MTProxy 已启动${re}"
    echo -e "服务器IP：$ip"
    echo -e "服务器端口：$port"
    echo -e "MTProxy Secret: ee${secret}636c6f7564666c6172652e636f6d"
    echo -e "TG 一键链接:"
    echo "  https://t.me/proxy?server=$ip&port=$port&secret=ee${secret}636c6f7564666c6172652e636f6d"
    echo "  tg://proxy?server=$ip&port=$port&secret=ee${secret}636c6f7564666c6172652e636f6d"
}

# ========== 卸载 MTProxy ==========
uninstall_mtproxy() {
    docker rm -f mtproxy >/dev/null 2>&1 || true
    echo -e "${red}❌ MTProxy 已卸载${re}"
}

# ========== 查看日志 ==========
logs_mtproxy() {
    docker logs -f mtproxy
}

# ========== 修改配置 ==========
modify_mtproxy() {
    echo -e "${green}请输入新端口 (回车跳过):${re}"
    read -r port
    [[ -z "$port" ]] && port=443

    echo -e "${green}请输入新密钥 (回车随机):${re}"
    read -r secret
    [[ -z "$secret" ]] && secret=$(openssl rand -hex 16)

    echo -e "${green}选择白名单模式:${re}"
    echo " 1) OFF"
    echo " 2) IP"
    echo " 3) IPSEG"
    read -r mode
    case $mode in
        2) ip_white_list="IP" ;;
        3) ip_white_list="IPSEG" ;;
        *) ip_white_list="OFF" ;;
    esac

    docker rm -f mtproxy >/dev/null 2>&1 || true

    docker run -d --name mtproxy --restart=always \
      -e domain="cloudflare.com" \
      -e secret="$secret" \
      -e ip_white_list="$ip_white_list" \
      -p ${port}:${port} \
      ellermister/mtproxy

    sleep 3
    show_info "$port" "$secret"
}

# ========== 菜单 ==========
while true; do
    clear
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}       MTProxy 一键管理脚本           ${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    echo -e "${green}1) 安装并启动 MTProxy${re}"
    echo -e "${green}2) 修改配置${re}"
    echo -e "${green}3) 查看日志${re}"
    echo -e "${green}4) 卸载 MTProxy${re}"
    echo -e "${green}0) 退出${re}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
    read -p "请输入选项: " choice

    case $choice in
        1) install_mtproxy ;;
        2) modify_mtproxy ;;
        3) logs_mtproxy ;;
        4) uninstall_mtproxy ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项${re}" ;;
    esac
    read -p "按回车键返回菜单..."
done
