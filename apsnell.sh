#!/bin/sh
# =========================================
# 作者: jinqians
# 日期: 2025年7月25日
# 描述: Alpine Linux 下 Snell v4/v5 安装与管理脚本
# =========================================

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RESET='\033[0m'

current_version="1.1"

INSTALL_DIR="/usr/local/bin"
SNELL_CONF_DIR="/etc/snell"
SNELL_CONF_FILE="${SNELL_CONF_DIR}/users/snell-main.conf"
OPENRC_SERVICE_FILE="/etc/init.d/snell"
SNELL_COMMAND=""

check_root() { [ "$(id -u)" != "0" ] && echo -e "${RED}请用 root 执行${RESET}" && exit 1; }
check_system() { [ ! -f /etc/alpine-release ] && echo -e "${RED}仅支持 Alpine Linux${RESET}" && exit 1; }

install_dependencies() {
    echo -e "${CYAN}安装依赖...${RESET}"
    apk update
    apk add curl wget unzip openssl iptables openrc net-tools file gcompat libc6-compat libstdc++ libgcc
    # glibc
    GLIBC_VERSION="2.35-r0"
    curl -sL -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
    for pkg in glibc glibc-bin glibc-i18n; do
        curl -sLO "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}-${GLIBC_VERSION}.apk"
        apk add --allow-untrusted --force-overwrite "${pkg}-${GLIBC_VERSION}.apk"
        rm -f "${pkg}-${GLIBC_VERSION}.apk"
    done
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 >/dev/null 2>&1
    grep -q 'LD_LIBRARY_PATH' /etc/profile || echo 'export LD_LIBRARY_PATH="/usr/glibc-compat/lib:${LD_LIBRARY_PATH}"' >> /etc/profile
    grep -q 'GLIBC_TUNABLES' /etc/profile || echo 'export GLIBC_TUNABLES=glibc.pthread.rseq=0' >> /etc/profile
    . /etc/profile
}

select_snell_version() {
    echo -e "${CYAN}选择 Snell 版本:${RESET}"
    echo -e "${GREEN}1.${RESET} v4"
    echo -e "${GREEN}2.${RESET} v5"
    while true; do
        printf "选项 [1-2]: "
        read -r v
        case "$v" in 1) SNELL_VERSION_CHOICE="v4"; break ;; 2) SNELL_VERSION_CHOICE="v5"; break ;; *) echo -e "${RED}请输入 1 或 2${RESET}" ;; esac
    done
}

get_latest_snell_v4_version() {
    ver=$(curl -s https://manual.nssurge.com/others/snell.html | grep -o 'snell-server-v4\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/snell-server-v//')
    echo "${ver:-4.0.1}"
}

get_latest_snell_v5_version() {
    ver=$(curl -s https://manual.nssurge.com/others/snell.html | grep -o 'snell-server-v5\.[0-9]\+\.[0-9]\+b[0-9]\+' | head -n1 | sed 's/snell-server-v//')
    echo "${ver:-5.0.0}"
}

get_latest_snell_version() {
    SNELL_VERSION=$( [ "$SNELL_VERSION_CHOICE" = "v5" ] && get_latest_snell_v5_version || get_latest_snell_v4_version )
    echo -e "${GREEN}版本: ${SNELL_VERSION}${RESET}"
}

get_snell_download_url() {
    arch=$(uname -m)
    case $arch in
        x86_64|amd64) arch_suffix="amd64" ;;
        aarch64|arm64) arch_suffix="aarch64" ;;
        armv7l|armv7) arch_suffix="armv7l" ;;
        *) echo -e "${RED}不支持架构: $arch${RESET}" ; exit 1 ;;
    esac
    echo "https://dl.nssurge.com/snell/snell-server-${SNELL_VERSION}-linux-${arch_suffix}.zip"
}

get_user_port() {
    while true; do
        printf "端口 (1-65535, 回车随机): "
        read -r PORT
        if [ -z "$PORT" ]; then PORT=$(shuf -i20000-65000 -n1); echo -e "${YELLOW}随机端口: $PORT${RESET}"; break; fi
        [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] && break || echo -e "${RED}无效端口${RESET}"
    done
}

open_port() {
    iptables -I INPUT -p tcp --dport "$1" -j ACCEPT
    /etc/init.d/iptables save >/dev/null
    rc-update add iptables boot >/dev/null
}

create_management_script() {
    cat > /usr/local/bin/snell << 'EOF'
#!/bin/sh
RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'
if [ "$(id -u)" != "0" ]; then echo -e "${RED}请用 root 执行${RESET}"; exit 1; fi
TMP=$(mktemp)
curl -sL https://raw.githubusercontent.com/jinqians/snell.sh/main/snell-alpine.sh -o "$TMP" && sh "$TMP"
rm -f "$TMP"
EOF
    chmod +x /usr/local/bin/snell
}

install_snell() {
    check_root
    [ -f "$OPENRC_SERVICE_FILE" ] && echo -e "${YELLOW}已安装${RESET}" && return
    install_dependencies
    select_snell_version
    get_latest_snell_version
    URL=$(get_snell_download_url)
    mkdir -p "$INSTALL_DIR"
    cd /tmp || exit 1
    echo -e "${CYAN}下载 Snell ${SNELL_VERSION}...${RESET}"
    curl -L -o snell_temp "$URL" || { echo -e "${RED}下载失败${RESET}"; exit 1; }
    FILE_TYPE=$(file snell_temp)
    if echo "$FILE_TYPE" | grep -q 'Zip archive'; then
        unzip -o snell_temp || { echo -e "${RED}解压失败${RESET}"; exit 1; }
        mv snell-server "$INSTALL_DIR/"
    elif echo "$FILE_TYPE" | grep -q 'ELF 64-bit'; then
        mv snell_temp "$INSTALL_DIR/snell-server"
    else
        echo -e "${RED}未知文件类型${RESET}"; exit 1
    fi
    chmod +x "$INSTALL_DIR/snell-server"
    rm -f snell_temp
    # wrapper
    cat > "$INSTALL_DIR/snell-server-wrapper" << EOF
#!/bin/sh
export LD_LIBRARY_PATH="/usr/glibc-compat/lib:\${LD_LIBRARY_PATH}"
export GLIBC_TUNABLES="glibc.pthread.rseq=0"
exec /usr/local/bin/snell-server "\$@"
EOF
    chmod +x "$INSTALL_DIR/snell-server-wrapper"
    SNELL_COMMAND="$INSTALL_DIR/snell-server-wrapper"
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
    # OpenRC
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
start_pre() { checkpath --directory --owner nobody:nobody --mode 0755 /var/log/snell; [ ! -f "/etc/snell/users/snell-main.conf" ] && eerror "配置不存在" && return 1; }
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

uninstall_snell() {
    check_root
    [ ! -f "$OPENRC_SERVICE_FILE" ] && echo -e "${YELLOW}未安装${RESET}" && return
    rc-service snell stop
    rc-update del snell default
    [ -f "$SNELL_CONF_FILE" ] && PORT=$(grep listen "$SNELL_CONF_FILE" | cut -d: -f2 | tr -d ' ') && iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null
    rm -f "$OPENRC_SERVICE_FILE" "$INSTALL_DIR/snell-server" "$INSTALL_DIR/snell-server-wrapper"
    rm -rf "$SNELL_CONF_DIR" /var/log/snell
    echo -e "${GREEN}卸载完成${RESET}"
}

restart_snell() { check_root; rc-service snell restart; sleep 2; }
show_information() {
    [ ! -f "$SNELL_CONF_FILE" ] && echo -e "${RED}配置不存在${RESET}" && return
    PORT=$(grep listen "$SNELL_CONF_FILE" | cut -d: -f2 | tr -d ' ')
    PSK=$(grep psk "$SNELL_CONF_FILE" | sed 's/psk\s*=\s*//')
    INSTALLED_VERSION_CHOICE=$(grep version-choice "$SNELL_CONF_FILE" | sed 's/version-choice\s*=\s*//')
    [ -z "$INSTALLED_VERSION_CHOICE" ] && INSTALLED_VERSION_CHOICE="v4"
    IPV4=$(curl -s4 https://api.ipify.org)
    IPV6=$(curl -s6 https://api64.ipify.org)
    echo -e "${GREEN}IPV4:$IPV4 端口:$PORT PSK:$PSK 版本:$INSTALLED_VERSION_CHOICE${RESET}"
    echo -e "${GREEN}IPV6:$IPV6 端口:$PORT PSK:$PSK 版本:$INSTALLED_VERSION_CHOICE${RESET}"
}
check_status() { check_root; rc-service snell status; [ -f /var/log/snell/snell.log ] && tail -10 /var/log/snell/snell.log; }

show_menu() {
    clear
    echo -e "${CYAN}=== Snell 管理 v${current_version} ===${RESET}"
    [ -f "$OPENRC_SERVICE_FILE" ] && rc-service snell status | grep -q started && echo -e "状态: ${GREEN}运行中${RESET}" || echo -e "状态: ${RED}未运行${RESET}"
    echo -e "${GREEN}1.${RESET} 安装 Snell"
    echo -e "${GREEN}2.${RESET} 卸载 Snell"
    echo -e "${GREEN}3.${RESET} 重启服务"
    echo -e "${GREEN}4.${RESET} 查看配置信息"
    echo -e "${GREEN}5.${RESET} 查看状态"
    echo -e "${GREEN}0.${RESET} 退出"
    printf "选项 [0-5]: "
    read -r num
}

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
        *) echo -e "${RED}请输入正确选项${RESET}" ;;
    esac
    printf "${CYAN}按任意键返回菜单...${RESET}"; read -r dummy
done
