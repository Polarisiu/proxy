#!/bin/bash
# 3x-ui Alpine 管理菜单

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
plain="\033[0m"

show_menu() {
    clear
    echo -e "${green}=========== 3x-ui 管理面板 (Alpine) ===========${plain}"
    echo -e " ${yellow}1.${plain} 安装 3x-ui"
    echo -e " ${yellow}2.${plain} 卸载 3x-ui"
    echo -e " ${yellow}3.${plain} 启动 3x-ui"
    echo -e " ${yellow}4.${plain} 停止 3x-ui"
    echo -e " ${yellow}5.${plain} 重启 3x-ui"
    echo -e " ${yellow}6.${plain} 更新 geoip"
    echo -e " ${yellow}0.${plain} 退出"
    echo -e "${green}===============================================${plain}"
    echo
}

install_3xui() {
    apk update && apk add --no-cache curl bash gzip openssl
    bash <(curl -Ls https://raw.githubusercontent.com/StarVM-OpenSource/3x-ui-Apline/refs/heads/main/install.sh)
}

uninstall_3xui() {
    echo -e "${red}正在卸载 3x-ui...${plain}"
    x-ui uninstall
}

start_3xui() {
    x-ui start
}

stop_3xui() {
    x-ui stop
}

restart_3xui() {
    x-ui restart
}

update_geoip() {
    cd /usr/local/x-ui/bin || exit
    curl -L -o geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat
    curl -L -o geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat
    echo -e "${green}更新完成，正在重启 x-ui...${plain}"
    x-ui restart
} 



while true; do
    show_menu
    read -rp "请输入选项: " choice
    case "$choice" in
        1) install_3xui ;;
        2) uninstall_3xui ;;
        3) start_3xui ;;
        4) stop_3xui ;;
        5) restart_3xui ;;
        6) update_geoip ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项，请重新输入${plain}" ;;
    esac
    echo
    read -rp "按回车键返回菜单..."
done
