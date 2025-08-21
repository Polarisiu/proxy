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
    echo -e "${GREEN}=== FRP-Panel部署菜单 ===${NC}"
    echo -e "${GREEN}01) Master 部署${NC}"
    echo -e "${GREEN}02) Server 部署${NC}"
    echo -e "${GREEN}03) Client 部署${NC}"
    echo -e "${GREEN}04) 卸载 Master${NC}"
    echo -e "${GREEN}05) 卸载 Server${NC}"
    echo -e "${GREEN}06) 卸载 Client${NC}"
    echo -e "${GREEN}07) 更新 Master 镜像${NC}"
    echo -e "${GREEN}08) 更新 Server 镜像${NC}"
    echo -e "${GREEN}09) 更新 Client 镜像${NC}"
    echo -e "${GREEN}10) 查看 Master 日志${NC}"
    echo -e "${GREEN}11) 查看 Server 日志${NC}"
    echo -e "${GREEN}12) 查看 Client 日志${NC}"
    echo -e "${GREEN}0)  退出${NC}"
    read -rp "请输入编号: " choice

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
        4|04)
            docker rm -f frp-panel-master
            echo -e "${GREEN}Master 卸载完成，按回车返回菜单${NC}"
            read -r
            ;;
        5|05)
            docker rm -f frp-panel-server
            echo -e "${GREEN}Server 卸载完成，按回车返回菜单${NC}"
            read -r
            ;;
        6|06)
            docker rm -f frp-panel-client
            echo -e "${GREEN}Client 卸载完成，按回车返回菜单${NC}"
            read -r
            ;;
        7|07)
            echo -e "${GREEN}正在更新 Master 镜像...${NC}"
            docker pull vaalacat/frp-panel
            echo -e "${GREEN}Master 镜像更新完成，按回车返回菜单${NC}"
            read -r
            ;;
        8|08)
            echo -e "${GREEN}正在更新 Server 镜像...${NC}"
            docker pull vaalacat/frp-panel
            echo -e "${GREEN}Server 镜像更新完成，按回车返回菜单${NC}"
            read -r
            ;;
        9|09)
            echo -e "${GREEN}正在更新 Client 镜像...${NC}"
            docker pull vaalacat/frp-panel
            echo -e "${GREEN}Client 镜像更新完成，按回车返回菜单${NC}"
            read -r
            ;;
        10)
            docker logs -f frp-panel-master
            echo -e "${GREEN}按回车返回菜单${NC}"
            read -r
            ;;
        11)
            docker logs -f frp-panel-server
            echo -e "${GREEN}按回车返回菜单${NC}"
            read -r
            ;;
        12)
            docker logs -f frp-panel-client
            echo -e "${GREEN}按回车返回菜单${NC}"
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
