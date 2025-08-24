#!/bin/sh
# =========================================
# Alpine Snell 管理脚本
# 作者: ChatGPT
# 日期: 2025-08-24
# 功能: 安装/卸载/管理 Snell v4/v5
# =========================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RESET='\033[0m'

# --- 全局变量 ---
SNELL_VERSION_CHOICE=""
SNELL_VERSION=""
SNELL_COMMAND=""
INSTALL_DIR="/usr/local/bin"
SNELL_CONF_DIR="/etc/snell"
SNELL_CONF_FILE="${SNELL_CONF_DIR}/users/snell-main.conf"
OPENRC_SERVICE_FILE="/etc/init.d/snell"
current_version="1.0"

# --- 基础函数 ---
check_root() {
    [ "$(id -u)" != "0" ] && echo -e "${RED}请以 root 权限运行${RESET}" && exit 1
}
check_system() {
    [ ! -f /etc/alpine-release ] && echo -e "${RED}此脚本仅适用于 Alpine${RESET}" && exit 1
}

# --- 安装依赖 ---
install_dependencies() {
    echo -e "${CYAN}更新软件源并安装依赖...${RESET}"
    apk update
    apk add curl wget unzip openssl iptables openrc net-tools file gcompat libc6-compat libstdc++ libgcc
}

# --- 选择版本 ---
select_snell_version() {
    echo -e "${CYAN}请选择 Snell 版本:${RESET}"
    echo -e "${GREEN}1.${RESET} v4"
    echo -e "${GREEN}2.${RESET} v5"
    while true; do
        read -rp "请输入选项 [1-2]: " choice
        case "$choice" in
            1) SNELL_VERSION_CHOICE="v4"; break ;;
            2) SNELL_VERSION_CHOICE="v5"; break ;;
            *) echo -e "${RED}请输入正确选项[1-2]${RESET}" ;;
        esac
    done
}

get_latest_snell_version() {
    if [ "$SNELL_VERSION_CHOICE" = "v5" ]; then
        SNELL_VERSION=$(curl -s https://manual.nssurge.com/others/snell.html | grep -o 'snell-server-v5\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/snell-server-v//')
    else
        SNELL_VERSION=$(curl -s https://manual.nssurge.com/others/snell.html | grep -o 'snell-server-v4\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/snell-server-v//')
    fi
    [ -z "$SNELL_VERSION" ] && SNELL_VERSION="v${SNELL_VERSION_CHOICE}.0.1"
    echo -e "${GREEN}获取到版本: ${SNELL_VERSION}${RESET}"
}

get_snell_download_url() {
    arch=$(uname -m)
    case $arch in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="aarch64" ;;
        armv7l|armv7) arch="armv7l" ;;
        *) echo -e "${RED}不支持架构: $arch${RESET}"; exit 1 ;;
    esac
    echo "https://dl.nssurge.com/snell/snell-server-${SNELL_VERSION}-linux-${arch}.zip"
}

# --- 获取端口 ---
get_user_port() {
    while true; do
        read -rp "请输入端口 (回车随机): " PORT
        if [ -z "$PORT" ]; then
            PORT=$(shuf -i 20000-65000 -n1)
            echo -e "${YELLOW}使用随机端口: $PORT${RESET}"
            break
        fi
        case "$PORT" in
            ''|*[!0-9]*) echo -e "${RED}请输入纯数字${RESET}" ;;
            *) [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] && break || echo -e "${RED}端口范围 1-65535${RESET}" ;;
        esac
    done
}

# --- 开放防火墙端口 ---
open_port() {
    iptables -I INPUT -p tcp --dport "$1" -j ACCEPT
    /etc/init.d/iptables save
    rc-update add iptables boot
    echo -e "${GREEN}端口 $1 已开放${RESET}"
}

# --- 创建管理脚本 ---
create_management_script() {
    cat > /usr/local/bin/snell << EOF
#!/bin/sh
RED='\\033[0;31m'; CYAN='\\033[0;36m'; RESET='\\033[0m'
if [ "\$(id -u)" != "0" ]; then echo -e "\${RED}请以 root 权限运行\${RESET}"; exit 1; fi
TMP=\$(mktemp)
curl -sL https://raw.githubusercontent.com/Polarisiu//proxy/main/apsnell.sh -o "\$TMP" && sh "\$TMP"
rm -f "\$TMP"
EOF
    chmod +x /usr/local/bin/snell
}

# --- 安装 Snell ---
install_snell() {
    check_root
    [ -f "$OPENRC_SERVICE_FILE" ] && echo -e "${YELLOW}已安装${RESET}" && return
    install_dependencies
    select_snell_version
    get_latest_snell_version
    SNELL_URL=$(get_snell_download_url)
    mkdir -p "$INSTALL_DIR"
    cd /tmp
    curl -L -o snell.zip "$SNELL_URL"
    unzip -o snell.zip
    mv snell-server "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/snell-server"
    rm -f snell.zip

    # wrapper
    cat > "$INSTALL_DIR/snell-server-wrapper" << 'EOF'
#!/bin/sh
export LD_LIBRARY_PATH="/usr/glibc-compat/lib:${LD_LIBRARY_PATH}"
export GLIBC_TUNABLES="glibc.pthread.rseq=0"
exec /usr/local/bin/snell-server "$@"
EOF
    chmod +x "$INSTALL_DIR/snell-server-wrapper"
    SNELL_COMMAND="$INSTALL_DIR/snell-server-wrapper"

    # 配置文件
    mkdir -p "$SNELL_CONF_DIR/users" /var/log/snell
    get_user_port
    PSK=$(openssl rand -base64 16)
    cat > "$SNELL_CONF_FILE" << EOF
[snell-server]
listen = 0.0.0.0:${PORT}
psk = ${PSK}
ipv6 = true
tfo = true
version-choice = ${SNELL_VERSION_CHOICE}
EOF

    # OpenRC 服务
    cat > "$OPENRC_SERVICE_FILE" << EOF
#!/sbin/openrc-run
name="Snell Server"
description="Snell proxy server"
command="${SNELL_COMMAND}"
command_args="-c /etc/snell/users/snell-main.conf"
command_user="nobody"
command_background="yes"
pidfile="/run/snell.pid"
start_stop_daemon_args="--make-pidfile --stdout /var/log/snell/snell.log --stderr /var/log/snell/snell.log"
depend() { need net; after firewall; }
start_pre() {
    checkpath --directory --owner nobody:nobody --mode 0755 /var/log/snell
    [ ! -f "/etc/snell/users/snell-main.conf" ] && eerror "配置文件不存在" && return 1
}
stop_post() { [ -f "\${pidfile}" ] && rm -f "\${pidfile}"; }
EOF
    chmod +x "$OPENRC_SERVICE_FILE"

    rc-update add snell default
    rc-service snell start
    sleep 2
    open_port "$PORT"
    create_management_script
    echo -e "${GREEN}安装完成！端口:$PORT, PSK:$PSK, 版本:$SNELL_VERSION_CHOICE${RESET}"
}

# --- 卸载 Snell ---
uninstall_snell() {
    check_root
    [ ! -f "$OPENRC_SERVICE_FILE" ] && echo -e "${YELLOW}未安装${RESET}" && return
    rc-service snell stop
    rc-update del snell default
    [ -f "$SNELL_CONF_FILE" ] && PORT=$(grep 'listen' "$SNELL_CONF_FILE" | cut -d':' -f2 | tr -d ' ') && iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null
    rm -f "$OPENRC_SERVICE_FILE" "$INSTALL_DIR/snell-server" "$INSTALL_DIR/snell-server-wrapper"
    rm -rf "$SNELL_CONF_DIR" /var/log/snell
    echo -e "${GREEN}卸载完成${RESET}"
}

# --- 重启服务 ---
restart_snell() { rc-service snell restart; sleep 2; rc-service snell status; }

# --- 查看信息 ---
show_information() {
    [ ! -f "$SNELL_CONF_FILE" ] && echo -e "${RED}未找到配置文件${RESET}" && return
    PORT=$(grep 'listen' "$SNELL_CONF_FILE" | sed 's/.*://')
    PSK=$(grep 'psk' "$SNELL_CONF_FILE" | sed 's/psk\s*=\s*//')
    VERSION=$(grep 'version-choice' "$SNELL_CONF_FILE" | sed 's/version-choice\s*=\s*//')
    IPV4=$(curl -s4 https://api.ipify.org)
    echo -e "${GREEN}Snell 信息:${RESET}\nIPV4:$IPV4\n端口:$PORT\nPSK:$PSK\n版本:$VERSION"
}

# --- 查看状态 ---
check_status() {
    rc-service snell status
    [ -f /var/log/snell/snell.log ] && tail -10 /var/log/snell/snell.log || echo "日志不存在"
}

# --- 菜单 ---
show_menu() {
    clear
    echo -e "${CYAN}=== Snell 管理脚本 v${current_version} ===${RESET}"
    [ -f "$OPENRC_SERVICE_FILE" ] && rc-service snell status | grep -q started && echo -e "状态: ${GREEN}运行中${RESET}" || echo -e "状态: ${RED}未运行${RESET}"
    echo -e "${GREEN}1.${RESET} 安装 Snell"
    echo -e "${GREEN}2.${RESET} 卸载 Snell"
    echo -e "${GREEN}3.${RESET} 重启服务"
    echo -e "${GREEN}4.${RESET} 查看配置信息"
    echo -e "${GREEN}5.${RESET} 查看状态"
    echo -e "${GREEN}0.${RESET} 退出"
    printf "请输入选项 [0-5]: "
    read -r num
}

# --- 主循环 ---
check_root
check_system
while true; do
    show_menu
    case "$num" in
        1) install_snell ;;
        2) uninstall_snell ;;
        3) restart_snell ;;
        4) show_information ;;
        5) check_status ;;
        0) echo -e "${GREEN}退出${RESET}"; exit 0 ;;
        *) echo -e "${RED}请输入正确选项[0-5]${RESET}" ;;
    esac
    printf "${CYAN}按任意键返回菜单...${RESET}"
    read -r dummy
done
