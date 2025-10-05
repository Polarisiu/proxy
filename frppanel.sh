#!/bin/bash
# ==========================================
# FRP-Panel 一键管理菜单脚本
# 支持 Master / Server / Client 部署、卸载、更新、查看日志
# 执行完操作自动返回菜单
# ==========================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

while true; do
    clear
    echo -e "${GREEN}=== FRP-Panel 部署菜单 ===${NC}"
    echo -e "${GREEN}1. Master 面板部署${NC}"
    echo -e "${GREEN}2. Server 服务端部署${NC}"
    echo -e "${GREEN}3. Client 客户端部署${NC}"
    echo -e "${GREEN}0. 退出${NC}"
    read -rp "$(echo -e "${GREEN}请输入编号:${NC} ")" choice

    case $choice in
        1|01)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Master.sh)
            ;;
        2|02)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/server.sh)
            ;;
        3|03)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Client.sh)
            ;;
        0|00)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新输入。${NC}"
            ;;
    esac

    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})" temp
done
