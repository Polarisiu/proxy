#!/bin/bash
# ==========================================
# FRP-Panel 一键管理菜单脚本
# 支持 Master / Server / Client 部署、卸载、更新、查看日志
# 执行完操作自动返回菜单
# 日志查看退出后也返回菜单
# 菜单编号补零显示
# 更新镜像针对对应容器
# ==========================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

while true; do
    clear
    echo -e "${GREEN}=== FRP-Panel部署菜单 ===${NC}"
    echo -e "${GREEN}01) Master 面板部署${NC}"
    echo -e "${GREEN}02) Server 服务端部署${NC}"
    echo -e "${GREEN}03) Client 客户端部署${NC}"
    echo -e "${GREEN} 0) 退出${NC}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice

    case $choice in
        1|01)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Master.sh)
            echo -e "${GREEN}Master 部署完成，按回车返回菜单${NC}"
            read -r
            ;;
        2|02)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/server.sh)
            echo -e "${GREEN}Server 部署完成，按回车返回菜单${NC}"
            read -r
            ;;
        3|03)
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Client.sh)
            echo -e "${GREEN}Client 部署完成，按回车返回菜单${NC}"
            read -r
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新输入${NC}"
            ;;
    esac
    echo
done
