#!/bin/bash
# ==========================================
# FRP-Panel Master 管理脚本
# 支持安装/卸载/更新/查看日志
# 卸载可选择是否清理数据
# 部署完成后返回菜单
# 菜单字体为绿色
# ==========================================

set -e

DATA_DIR="/opt/frpp/data"
COMPOSE_FILE="docker-compose.yml"

# -----------------------------
# 颜色定义
# -----------------------------
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

while true; do
    echo -e "${GREEN}=====Master管理菜单=======${NC}"
    echo -e "${GREEN}1) 安装部署 Master${NC}"
    echo -e "${GREEN}2) 卸载 Master${NC}"
    echo -e "${GREEN}3) 更新 Master${NC}"
    echo -e "${GREEN}4) 查看 Master日志${NC}"
    echo -e "${GREEN}0)退出${NC}"
    read -p "输入选项 : " choice

    case "$choice" in
    1)
        # -----------------------------
        # 安装 / 部署 Master
        # -----------------------------
        read -p "请输入 Master 密钥 (APP_GLOBAL_SECRET): " APP_SECRET
        [ -z "$APP_SECRET" ] && { echo "密钥不能为空！"; continue; }

        read -p "请输入 Master RPC 绑定 IP 或域名 (MASTER_RPC_HOST, 默认 127.0.0.1): " MASTER_RPC_HOST
        MASTER_RPC_HOST=${MASTER_RPC_HOST:-127.0.0.1}

        read -p "请输入 Master RPC 端口 (MASTER_RPC_PORT, 默认 9001): " RPC_PORT
        RPC_PORT=${RPC_PORT:-9001}

        read -p "请输入 Master API IP 或域名 (MASTER_API_HOST, 默认 127.0.0.1): " MASTER_API_HOST
        MASTER_API_HOST=${MASTER_API_HOST:-127.0.0.1}

        read -p "请输入 Master API 端口 (MASTER_API_PORT, 默认 9000): " API_PORT
        API_PORT=${API_PORT:-9000}

        read -p "请输入 Master API 协议 (MASTER_API_SCHEME, 默认 http): " MASTER_API_SCHEME
        MASTER_API_SCHEME=${MASTER_API_SCHEME:-http}

        read -p "请输入数据存储目录 (DATA_DIR, 默认 /opt/frpp/data): " INPUT_DIR
        DATA_DIR=${INPUT_DIR:-$DATA_DIR}

        mkdir -p "$DATA_DIR"
        echo -e "${GREEN}数据目录已创建: $DATA_DIR${NC}"

        # 生成 docker-compose.yaml
        cat > "$COMPOSE_FILE" <<EOF

services:
  frpp-master:
    image: vaalacat/frp-panel:latest
    network_mode: host
    environment:
      APP_GLOBAL_SECRET: $APP_SECRET
      MASTER_RPC_HOST: $MASTER_RPC_HOST
      MASTER_RPC_PORT: $RPC_PORT
      MASTER_API_HOST: $MASTER_API_HOST
      MASTER_API_PORT: $API_PORT
      MASTER_API_SCHEME: $MASTER_API_SCHEME
    volumes:
      - $DATA_DIR:/data
    restart: unless-stopped
    command: master
EOF

        echo -e "${GREEN}docker-compose.yaml 已生成${NC}"
        echo -e "${GREEN}启动 FRP-Panel Master...${NC}"
        docker-compose up -d
        echo -e "${GREEN}✅ 部署完成！${NC}"
        ;;
    2)
        # -----------------------------
        # 卸载 Master
        # -----------------------------
        echo -e "${GREEN}停止并移除 Master...${NC}"
        docker-compose down

        read -p "是否删除数据目录 $DATA_DIR ? [y/N]: " del_data
        if [[ "$del_data" =~ ^[Yy]$ ]]; then
            rm -rf "$DATA_DIR"
            echo -e "${GREEN}✅ 数据目录已删除${NC}"
        fi
        echo -e "${GREEN}✅ Master 已卸载${NC}"
        ;;
    3)
        # -----------------------------
        # 更新 Master 镜像
        # -----------------------------
        echo -e "${GREEN}拉取最新镜像...${NC}"
        docker-compose pull
        echo -e "${GREEN}重新启动 Master...${NC}"
        docker-compose up -d
        echo -e "${GREEN}✅ Master 已更新${NC}"
        ;;
    4)
        # -----------------------------
        # 查看日志
        # -----------------------------
        echo -e "${GREEN}显示 Master 日志 (Ctrl+C 退出)...${NC}"
        docker-compose logs -f
        ;;
    5)
        echo -e "${GREEN}退出脚本${NC}"
        exit 0
        ;;
    *)
        echo -e "${GREEN}无效选项，请重新输入${NC}"
        ;;
    esac
done
