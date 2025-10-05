#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED="\033[31m"
NC='\033[0m' # 不带颜色

# 菜单函数
show_menu() {
    echo -e "${GREEN}===== FRP 管理工具安装 ===${NC}"
    echo -e "${GREEN}1. 安装 FRP-Panel (带 Web 面板)${NC}"
    echo -e "${GREEN}2. 安装 FRP 工具 (快速部署 FRP 服务端/客户端)${NC}"
    echo -e "${GREEN}3. 安装 frpc-manager (客户端管理)${NC}"
    echo -e "${GREEN}0. 退出${NC}"
    echo -n -e "${GREEN}请选择: ${NC}"
}

# 安装函数
install_frp_panel() {
    echo -e "${GREEN}开始安装 FRP-Panel...${NC}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/frppanel.sh)
    echo -e "${GREEN}安装完成，按回车返回菜单...${NC}"
    read
}

install_frp_tool() {
    echo -e "${GREEN}开始安装 FRP 工具...${NC}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nuro-frp/main/install.sh)
    echo -e "${GREEN}安装完成，按回车返回菜单...${NC}"
    read
}

install_frpc_manager() {
    echo -e "${GREEN}开始安装 frpc-manager...${NC}"
    bash <(curl -fsSL https://raw.githubusercontent.com/zeyu8023/frpc-manager/main/bootstrap.sh)
    echo -e "${GREEN}安装完成，按回车返回菜单...${NC}"
    read
}

# 主循环
while true; do
    show_menu
    read choice
    case $choice in
        1) install_frp_panel ;;
        2) install_frp_tool ;;
        3) install_frpc_manager ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}输入无效，请重新选择${NC}"
            ;;
    esac
done
