#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== GOST 安装菜单 ===${RESET}"
    echo -e "${GREEN}1) 国外 EZGost 安装${RESET}"
    echo -e "${GREEN}2) 国内 EZGost 安装${RESET}"
    echo -e "${GREEN}3) GOST 简化版安装${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装国外 EZGost...${RESET}"
            wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装国内 EZGost...${RESET}"
            wget --no-check-certificate -O gost.sh https://mirror.ghproxy.com/https://raw.githubusercontent.com/qqrrooty/EZgost/main/CN/gost.sh && chmod +x gost.sh && ./gost.sh
            pause
            ;;
        3)
            echo -e "${GREEN}正在安装 GOST 简化版...${RESET}"
            bash <(curl -sSL https://raw.githubusercontent.com/xmg0828-01/gost/main/gost.sh)
            pause
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${RESET}"
            sleep 1
            menu
            ;;
    esac
}

pause() {
    read -p $'\033[32m按回车键返回菜单...\033[0m'
    menu
}

menu
