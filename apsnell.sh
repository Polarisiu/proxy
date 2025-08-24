#!/bin/sh
# =========================================
# 作者: jinqians
# 日期: 2025年8月
# 描述: Alpine Linux Snell 安装与管理脚本 v1.1
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RESET='\033[0m'

current_version="1.1"
SNELL_VERSION_CHOICE=""
SNELL_VERSION=""
SNELL_COMMAND=""
INSTALL_DIR="/usr/local/bin"
SNELL_CONF_DIR="/etc/snell"
SNELL_CONF_FILE="${SNELL_CONF_DIR}/users/snell-main.conf"
OPENRC_SERVICE_FILE="/etc/init.d/snell"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 请以 root 权限运行${RESET}"
        exit 1
    fi
}

check_system() {
    if [ ! -f /etc/alpine-release ]; then
        echo -e "${RED}错误: 此脚本仅适用于 Alpine Linux${RESET}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${CYAN}更新软件源并安装依赖...${RESET}"
    apk update
    apk add curl wget unzip openssl iptables openrc net-tools file gcompat libc6-compat libstdc++ libgcc
    echo -e "${GREEN}依赖安装完成${RESET}"
}

select_snell_version() {
    echo -e "${CYAN}请选择 Snell 版本:${RESET}"
    echo -e "${GREEN}1.${RESET} Snell v4"
    echo -e "${GREEN}2.${RESET} Snell v5"
    while true; do
        printf "请输入选项 [1-2]: "
        read -r version_choice
        case "$version_choice" in
            1) SNELL_VERSION_CHOICE="v4"; break ;;
            2) SNELL_VERSION_CHOICE="v5"; break ;;
            *) echo -e "${RED}请输入正确选项 [1-2]${RESET}" ;;
        esac
    done
}

get_latest_snell_v4_version() { echo "v4.0.1"; }
get_latest_snell_v5_version() { echo "v5.0.0"; }

get_latest_snell_version() {
    if [ "$SNELL_VERSION_CHOICE" = "v5" ]; then SNELL_VERSION=$(get_latest_snell_v5_version); else SNELL_VERSION=$(get_latest_snell_v4_version); fi
    echo -e "${GREEN}获取到版本: ${SNELL_VERSION}${RESET}"
}

get_snell_download_url() {
    local arch=$(uname -m)
    local arch_suffix=""
    case $arch in
        x86_64|amd64) arch_suffix="amd64" ;;
        aarch64|arm64) arch_suffix="aarch64" ;;
        armv7l|armv7) arch_suffix="armv7l" ;;
        *) echo -e "${RED}不支持的架构: ${arch}${RESET}"; exit 1 ;;
    esac
    echo "https://dl.nssurge.com/snell/snell-server-${SNELL_VERSION}-linux-${arch_suffix}.zip"
}

get_user_port() {
    while true; do
        printf "请输入端口 (1-65535) 回车随机: "
        read -r PORT
        if [ -z "$PORT" ]; then PORT=$(shuf -i 20000-65000 -n 1); echo -e "${YELLOW}使用随机端口: $PORT${RESET}"; break; fi
        case "$PORT" in ''|*[!0-9]*) echo -e "${RED}请输入数字${RESET}"; continue;; esac
        if [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then break; else echo -e "${RED}端口无效${RESET}"; fi
    done
}

open_port() {
    local port=$1
    echo -e "${CYAN}配置防火墙端口 ${port}...${RESET}"
    iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT
    /etc/init.d/iptables save >/dev/null
    rc-update add iptables boot >/dev/null
    echo -e "${GREEN}防火墙已开放端口 ${port}${RESET}"
}

create_management_script() {
    echo -e "${CYAN}创建 snell 管理命令...${RESET}"
    local SCRIPT_URL="https://raw.githubusercontent.com/Polarisiu//proxy/main/apsnell.sh"
    cat > /usr/local/bin/snell << EOF
#!/bin/sh
RED='\\033[0;31m'; CYAN='\\033[0;36m'; RESET='\\033[0m'
if [ "\$(id -u)" != "0" ]; then echo -e "\${RED}请以 root 权限运行 (sudo snell)\${RESET}"; exit 1; fi
TMP_SCRIPT=\$(mktemp)
if curl -sL "${SCRIPT_URL}" -o "\$TMP_SCRIPT"; then
    sh "\$TMP_SCRIPT"
    rm -f "\$TMP_SCRIPT"
else
    echo -e "\${RED}下载失败${RESET}"; rm -f "\$TMP_SCRIPT"; exit 1
fi
EOF
    chmod +x /usr/local/bin/snell
    echo -e "${GREEN}✓ 管理命令 snell 已创建${RESET}"
}

show_manual_debug_info() {
    echo -e "${YELLOW}========== 手动调试 ==========${RESET}"
    echo "file ${INSTALL_DIR}/snell-server"
    echo "ldd ${INSTALL_DIR}/snell-server"
    echo "${INSTALL_DIR}/snell-server --help"
    echo "/usr/glibc-compat/lib/ld-linux-x86-64.so.2 ${INSTALL_DIR}/snell-server --help"
    echo -e "${YELLOW}==============================${RESET}"
}

install_snell() {
    check_root
    if [ -f "$OPENRC_SERVICE_FILE" ]; then echo -e "${YELLOW}已安装，请先卸载${RESET}"; return; fi
    install_dependencies
    select_snell_version
    get_latest_snell_version

    SNELL_URL=$(get_snell_download_url)
    echo -e "${CYAN}下载 Snell ${SNELL_VERSION}...${RESET}"
    mkdir -p "${INSTALL_DIR}"
    cd /tmp
    curl -L -o snell-server.zip "${SNELL_URL}" || { echo -e "${RED}下载失败${RESET}"; exit 1; }
    unzip -o snell-server.zip || { echo -e "${RED}解压失败${RESET}"; exit 1; }
    mv snell-server "${INSTALL_DIR}/"
    chmod +x "${INSTALL_DIR}/snell-server"
    rm -f snell-server.zip

    echo -e "${CYAN}执行兼容性测试...${RESET}"
    if file "${INSTALL_DIR}/snell-server" | grep -q "statically linked"; then
        SNELL_COMMAND="${INSTALL_DIR}/snell-server"
        echo -e "${GREEN}✓ 静态二进制可直接运行${RESET}"
    elif timeout 5s ${INSTALL_DIR}/snell-server --help >/dev/null 2>&1; then
        SNELL_COMMAND="${INSTALL_DIR}/snell-server"
        echo -e "${GREEN}✓ 动态二进制可直接运行${RESET}"
    elif timeout 5s /usr/glibc-compat/lib/ld-linux-x86-64.so.2 ${INSTALL_DIR}/snell-server --help >/dev/null 2>&1; then
        cat > ${INSTALL_DIR}/snell-server-wrapper << EOF
#!/bin/sh
export LD_LIBRARY_PATH="/usr/glibc-compat/lib:\${LD_LIBRARY_PATH}"
export GLIBC_TUNABLES="glibc.pthread.rseq=0"
exec /usr/glibc-compat/lib/ld-linux-x86-64.so.2 ${INSTALL_DIR}/snell-server "\$@"
EOF
        chmod +x ${INSTALL_DIR}/snell-server-wrapper
        SNELL_COMMAND="${INSTALL_DIR}/snell-server-wrapper"
        echo -e "${GREEN}✓ 使用 glibc wrapper 成功${RESET}"
    else
        echo -e "${RED}✗ 所有兼容性测试失败${RESET}"
        show_manual_debug_info
        exit 1
    fi

    mkdir -p "${SNELL_CONF_DIR}/users" "/var/log/snell"
    get_user_port
    PSK=$(openssl rand -base64 16)
    cat > ${SNELL_CONF_FILE} << EOF
[snell-server]
listen = 0.0.0.0:${PORT}
psk = ${PSK}
ipv6 = true
tfo = true
version-choice = ${SNELL_VERSION_CHOICE}
EOF

    cat > ${OPENRC_SERVICE_FILE} << EOF
#!/sbin/openrc-run
name="Snell Server"
description="Snell proxy server"
command="${SNELL_COMMAND}"
command_args="-c /etc/snell/users/snell-main.conf"
command_user="nobody"
command_background="yes"
pidfile="/run/snell.pid"
start_stop_daemon_args="--make-pidfile --stdout /var/log/snell/snell.log --stderr /var/log/snell/snell.log"
depend() {
    need net
    after firewall
}
start_pre() {
    checkpath --directory --owner nobody:nobody --mode 0755 /var/log/snell
    if [ ! -f "/etc/snell/users/snell-main.conf" ]; then eerror "配置文件不存在"; return 1; fi
    if [ ! -x "${SNELL_COMMAND}" ]; then eerror "Snell 二进制不存在或无执行权限"; return 1; fi
}
stop_post() { [ -f "\${pidfile}" ] && rm -f "\${pidfile}"; }
EOF
    chmod +x ${OPENRC_SERVICE_FILE}

    echo -e "${CYAN}启动服务...${RESET}"
    rc-update add snell default
    rc-service snell start
    sleep 2
    if rc-service snell status | grep -q "started"; then
        echo -e "${GREEN}✓ 服务运行正常${RESET}"
        open_port "$PORT"
        create_management_script
    else
        echo -e "${RED}✗ 服务状态异常，请查看日志${RESET}"
    fi
}

uninstall_snell() {
    check_root
    if [ ! -f "$OPENRC_SERVICE_FILE" ]; then echo -e "${YELLOW}Snell 未安装${RESET}"; return; fi
    rc-service snell stop 2>/dev/null
    rc-update del snell default 2>/dev/null
    PORT_TO_CLOSE=$(grep 'listen' ${SNELL_CONF_FILE} | cut -d':' -f2 | tr -d ' ')
    [ -n "$PORT_TO_CLOSE" ] && iptables -D INPUT -p tcp --dport "$PORT_TO_CLOSE" -j ACCEPT 2>/dev/null
    rm -f ${OPENRC_SERVICE_FILE} ${INSTALL_DIR}/snell-server ${INSTALL_DIR}/snell-server-wrapper
    rm -rf ${SNELL_CONF_DIR} /var/log/snell
    echo -e "${GREEN}Snell 已卸载${RESET}"
}

restart_snell() {
    check_root
    echo -e "${YELLOW}重启服务...${RESET}"
    rc-service snell restart; sleep 2
    rc-service snell status | grep -q "started" && echo -e "${GREEN}服务重启成功${RESET}" || echo -e "${RED}服务重启失败${RESET}"
}

show_information() {
    if [ ! -f "${SNELL_CONF_FILE}" ]; then echo -e "${RED}未找到配置文件${RESET}"; return; fi
    PORT=$(grep 'listen' ${SNELL_CONF_FILE} | sed 's/.*://')
    PSK=$(grep 'psk' ${SNELL_CONF_FILE} | sed 's/psk\s*=\s*//')
    INSTALLED_VERSION_CHOICE=$(grep 'version-choice' ${SNELL_CONF_FILE} | sed 's/version-choice\s*=\s*//')
    [ -z "$INSTALLED_VERSION_CHOICE" ] && INSTALLED_VERSION_CHOICE="v4"
    IPV4_ADDR=$(curl -s4 --connect-timeout 5 https://api.ipify.org)
    IPV6_ADDR=$(curl -s6 --connect-timeout 5 https://api64.ipify.org)
    clear
    echo -e "${BLUE}============================================${RESET}"
    echo -e "${GREEN}Snell 配置信息:${RESET}"
    echo -e "${BLUE}============================================${RESET}"
    [ -n "$IPV4_ADDR" ] && echo -e "${GREEN}IPv4: ${IPV4_ADDR} 端口: ${PORT} PSK: ${PSK} 版本: ${INSTALLED_VERSION_CHOICE}${RESET}"
    [ -n "$IPV6_ADDR" ] && echo -e "${GREEN}IPv6: ${IPV6_ADDR} 端口: ${PORT} PSK: ${PSK} 版本: ${INSTALLED_VERSION_CHOICE}${RESET}"
    echo -e "${BLUE}============================================${RESET}"
}

check_status() {
    check_root
    echo -e "${CYAN}=== 服务状态 ===${RESET}"
    rc-service snell status
    echo -e "${CYAN}=== 最新日志 (最后10行) ===${RESET}"
    [ -f "/var/log/snell/snell.log" ] && tail -10 /var/log/snell/snell.log || echo "日志不存在"
}

show_menu() {
    clear
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}     Snell 管理脚本 v${current_version}${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    if [ -f "$OPENRC_SERVICE_FILE" ]; then
        rc-service snell status | grep -q "started" && echo -e "服务状态: ${GREEN}运行中${RESET}" || echo -e "服务状态: ${RED}已停止${RESET}"
    else echo -e "服务状态: ${YELLOW}未安装${RESET}"; fi
    echo -e "1) 安装 Snell"
    echo -e "2) 卸载 Snell"
    echo -e "3) 重启服务"
    echo -e "4) 查看配置信息"
    echo -e "5) 查看服务状态"
    echo -e "0) 退出"
    echo -e "${CYAN}============================================${RESET}"
}

main_loop() {
    while true; do
        show_menu
        printf "请输入选项: "
        read -r choice
        case "$choice" in
            1) install_snell ;;
            2) uninstall_snell ;;
            3) restart_snell ;;
            4) show_information ;;
            5) check_status ;;
            0) echo -e "${GREEN}退出${RESET}"; exit 0 ;;
            *) echo -e "${RED}请输入正确选项${RESET}"; sleep 1 ;;
        esac
        echo -e "\n按回车返回菜单..."
        read -r
    done
}

check_root
check_system
main_loop
