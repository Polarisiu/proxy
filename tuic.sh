#!/bin/bash

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
skyblue="\033[36m"
re="\033[0m"

while true; do
    clear
    echo "--------------"
    echo -e "${green}1. 安装 TUIC${re}"
    echo -e "${red}2. 卸载 TUIC${re}"
    echo "--------------"
    echo -e "${skyblue}0. 退出${re}"
    echo "--------------"

    read -p $'\033[1;91m请输入你的选择: \033[0m' choice
    case $choice in
        1)
            bash <(curl -fsSL https://raw.githubusercontent.com/eooce/scripts/master/tuic.sh)
            ;;
        2)
            read -p "确认卸载 TUIC? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                pkill tuic
                rm -rf /root/tuic /root/tuic.sh
                echo -e "${red}TUIC 已卸载${re}"
            fi
            ;;
        0)
            echo -e "${skyblue}已退出脚本${re}"
            exit 0
            ;;
        *)
            echo -e "${red}无效输入！${re}"
            ;;
    esac
done
