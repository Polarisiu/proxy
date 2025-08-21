#!/bin/bash

# ================== 颜色定义 ==================
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
skyblue="\033[36m"
re="\033[0m"

# ================== 工具函数 ==================
random_port() {
    shuf -i 2000-65000 -n 1
}

check_port() {
    local port=$1
    while [[ -n $(lsof -i :$port 2>/dev/null) ]]; do
        echo -e "${red}${port}端口已经被占用，请更换端口重试${re}"
        read -p "请输入端口（直接回车使用随机端口）: " port
        [[ -z $port ]] && port=$(random_port) && echo -e "${green}使用随机端口: $port${re}"
    done
    echo $port
}

install_lsof() {
    if ! command -v lsof &>/dev/null; then
        if [ -f "/etc/debian_version" ]; then
            apt update && apt install -y lsof
        elif [ -f "/etc/alpine-release" ]; then
            apk add lsof
        fi
    fi
}

install_jq() {
    if ! command -v jq &>/dev/null; then
        if [ -f "/etc/debian_version" ]; then
            apt update && apt install -y jq
        elif [ -f "/etc/alpine-release" ]; then
            apk add jq
        fi
    fi
}

# ================== 主菜单 ==================
while true; do
    clear
    echo "--------------"
    echo -e "${green}1. 安装 Reality${re}"
    echo -e "${red}2. 卸载 Reality${re}"
    echo -e "${yellow}3. 更改 Reality 端口${re}"
    echo "--------------"
    echo -e "${skyblue}0. 退出${re}"
    echo "--------------"

    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
    case $sub_choice in
        1)
            clear
            install_lsof
            read -p $'\033[1;35m请输入Reality节点端口（回车随机端口）: \033[0m' port
            [[ -z $port ]] && port=$(random_port)
            port=$(check_port $port)

            if [ -f "/etc/alpine-release" ]; then
                PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/test.sh)"
            else
                PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/reality.sh)"
            fi
            echo -e "${green}Reality 安装完成！端口: $port${re}"
            sleep 1
            ;;
        2)
            clear
            if [ -f "/etc/alpine-release" ]; then
                pkill -f '[w]eb'
                pkill -f '[n]pm'
                rm -rf ~/app
            else
                sudo systemctl stop xray
                sudo rm -f /usr/local/bin/xray
                sudo rm -f /etc/systemd/system/xray.service
                sudo rm -f /usr/local/etc/xray/config.json
                sudo rm -f /usr/local/share/xray/geoip.dat
                sudo rm -f /usr/local/share/xray/geosite.dat
                sudo rm -f /etc/systemd/system/xray@.service
                sudo rm -rf /var/log/xray /var/lib/xray
                sudo systemctl daemon-reload
            fi
            echo -e "${green}Reality 已卸载${re}"
            sleep 1
            ;;
        3)
            clear
            install_jq
            read -p $'\033[1;35m请输入新 Reality 端口（回车随机端口）: \033[0m' new_port
            [[ -z $new_port ]] && new_port=$(random_port)
            new_port=$(check_port $new_port)

            if [ -f "/etc/alpine-release" ]; then
                jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' ~/app/config.json > tmp.json && mv tmp.json ~/app/config.json
                pkill -f '[w]eb'
                cd ~/app
                nohup ./web -c config.json >/dev/null 2>&1 &
            else
                jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                systemctl restart xray.service
            fi
            echo -e "${green}Reality端口已更换成 $new_port，请手动更新客户端配置！${re}"
            sleep 1
            ;;
        0)
            echo -e "${skyblue}已退出脚本${re}"
            exit 0
            ;;
        *)
            echo -e "${red}无效输入！${re}"
            sleep 1
            ;;
    esac
done
