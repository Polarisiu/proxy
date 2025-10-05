#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== EZRealm 安装菜单 ===${RESET}"
    echo -e "${GREEN}1) 国外机 EZRealm 安装${RESET}"
    echo -e "${GREEN}2) 国内机 EZRealm 安装${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装国外机 EZRealm...${RESET}"
            wget -N https://raw.githubusercontent.com/qqrrooty/EZrealm/main/realm.sh && chmod +x realm.sh && ./realm.sh
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装国内机 EZRealm...${RESET}"
            wget -N https://raw.githubusercontent.com/qqrrooty/EZrealm/main/CN/realm.sh && chmod +x realm.sh && ./realm.sh
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
