#!/bin/bash

# ========== 颜色 ==========
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
reset="\033[0m"

# ========== 通用函数 ==========
pause_and_return() {
    read -p $'\033[1;33m按回车键返回菜单...\033[0m'
}

# 随机生成 6 位字符串
random_str() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 6
}

# ========== H-UI 面板管理 ==========
menu_hui() {
    while true; do
        clear
        echo -e "${green}=== H-UI 面板管理===${reset}"
        echo -e "${green}1. 安装 H-UI 面板${reset}"
        echo -e "${green}2. 卸载 H-UI 面板${reset}"
        echo -e "${green}0. 退出${reset}"
        read -p $'\033[1;32m请输入你的选择: \033[0m' sub_choice
        case $sub_choice in
            1)
                echo -e "${yellow}正在安装 H-UI 面板...${reset}"
                bash <(curl -fsSL https://raw.githubusercontent.com/jonssonyan/h-ui/main/install.sh)

                # 生成随机用户名和密码
                USERNAME=$(random_str)
                PASSWORD=$(random_str)
                CONNECT_PASS="${USERNAME}.${PASSWORD}"

                echo -e "\n${green}✅ 安装完成${reset}"
                echo -e "${yellow}======== H-UI 面板信息 ========${reset}"
                echo -e "${green}面板端口: 8081${reset}"
                echo -e "${green}SSH 本地转发端口: 8082${reset}"
                echo -e "${green}登录用户名/密码: ${USERNAME} / ${PASSWORD}${reset}"
                echo -e "${green}连接密码: ${CONNECT_PASS}${reset}"
                echo -e "${yellow}================================${reset}"
                pause_and_return
                ;;
            2)
                echo -e "${yellow}正在卸载 H-UI 面板...${reset}"
                systemctl stop h-ui 2>/dev/null
                systemctl disable h-ui 2>/dev/null
                rm -rf /etc/systemd/system/h-ui.service /usr/local/h-ui/
                systemctl daemon-reload
                echo -e "${green}✅ H-UI 面板已卸载${reset}"
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
menu_hui
