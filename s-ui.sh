#!/bin/bash

# ========== 颜色 ==========
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
reset="\033[0m"

# ========== 通用函数 ==========
pause_and_return() {
    echo ""
    read -p $'\033[1;33m按回车键返回菜单...\033[0m'
}

# ========== Sui 面板管理 ==========
menu_sui() {
    while true; do
        clear
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
        echo -e "${green}       Sui 面板管理        ${reset}"
        echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
        echo -e "${green}1. 安装 Sui 面板${reset}"
        echo -e "${green}2. 卸载 Sui 面板${reset}"
        echo -e "${green}0. 退出${reset}"
        read -p $'\033[1;32m请输入你的选择: \033[0m' sub_choice
        case $sub_choice in
            1)
                echo -e "${yellow}正在安装 Sui 面板...${reset}"
                bash <(curl -Ls https://raw.githubusercontent.com/Misaka-blog/s-ui/master/install.sh)

                echo -e "\n${green}✅ 安装完成${reset}"
                echo -e "${yellow}======== Sui 默认面板信息 ========${reset}"
                echo -e "${green}面板端口：2095${reset}"
                echo -e "${green}面板路径：/app/${reset}"
                echo -e "${green}订阅端口：2096${reset}"
                echo -e "${green}订阅路径：/sub/${reset}"
                echo -e "${yellow}================================${reset}"
                pause_and_return
                ;;
            2)
                echo -e "${yellow}正在卸载 Sui 面板...${reset}"
                systemctl stop sing-box s-ui 2>/dev/null
                systemctl disable sing-box s-ui 2>/dev/null
                rm -f /etc/systemd/system/{s-ui,sing-box}.service
                systemctl daemon-reload
                rm -rf /usr/local/s-ui
                clear
                echo -e "${green}✅ Sui 面板已卸载${reset}"
                echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
                pause_and_return
                ;;
            0)
                exit 0
                ;;
            *)
                echo -e "${red}无效的输入！请重新选择${reset}"
                pause_and_return
                ;;
        esac
    done
}

# 启动菜单
menu_sui
