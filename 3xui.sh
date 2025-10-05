#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

pause() {
    read -p $'\033[32m按回车键返回菜单...\033[0m'
}

menu() {
    while true; do
        clear
        echo -e "${GREEN}=== 3XUI 安装菜单 ===${RESET}"
        echo -e "${GREEN}1) 原版3XUI安装${RESET}"
        echo -e "${GREEN}2) 中文版3XUI安装${RESET}"
        echo -e "${GREEN}3) Alpine版本3XUI安装${RESET}"
        echo -e "${GREEN}4) Docker3XUI安装${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        read -p $'\033[32m请选择操作: \033[0m' choice

        case $choice in
            1)
                echo -e "${GREEN}正在安装原版 3XUI...${RESET}"
                bash <(curl -fsSL https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
                pause
                ;;
            2)
                echo -e "${GREEN}正在安装中文版 3XUI...${RESET}"
                bash <(curl -fsSL https://raw.githubusercontent.com/xeefei/3x-ui/master/install.sh)
                pause
                ;;
            3)
                echo -e "${GREEN}正在安装 Alpine 版本 3XUI...${RESET}"
                bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xuiAlpine.sh)
                pause
                ;;
            4)
                echo -e "${GREEN}正在安装Docker 版本 3XUI...${RESET}"
                bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xuidocker.sh)
                pause
                ;;
            0)
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${RESET}"
                sleep 1
                ;;
        esac
    done
}

menu
