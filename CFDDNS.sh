#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[0;33m"
NC="\033[0m"
Info="${GREEN}[信息]${NC}"
Error="${RED}[错误]${NC}"
Tip="${YELLOW}[提示]${NC}"

DDNS_SCRIPT="/etc/DDNS/DDNS"
CONFIG_FILE="/etc/DDNS/.config"

# ================== 标题 ==================
show_title() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Cloudflare DDNS 自动更新脚本${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
}

# ================== 检查系统 ==================
if ! grep -qiE "debian|ubuntu|alpine" /etc/os-release; then
    echo -e "${RED}本脚本仅支持 Debian、Ubuntu 或 Alpine 系统，请在这些系统上运行。${NC}"
    exit 1
fi

if [[ $(whoami) != "root" ]]; then
    echo -e "${Error}请以root身份执行该脚本！"
    exit 1
fi

# ================== 检查 curl ==================
check_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}未检测到 curl，正在安装 curl...${NC}"
        if grep -qiE "debian|ubuntu" /etc/os-release; then
            apt update
            apt install -y curl
        elif grep -qiE "alpine" /etc/os-release; then
            apk update
            apk add curl
        fi
    fi
}

# ================== 获取公网 IP ==================
get_public_ip() {
    Public_IPv4=$(curl -s https://api.ipify.org)
    Public_IPv6=$(curl -s https://api6.ipify.org)
}

# ================== 安装 DDNS ==================
install_ddns() {
    mkdir -p /etc/DDNS
    if [ ! -f "$DDNS_SCRIPT" ]; then
        curl -o "$DDNS_SCRIPT" https://raw.githubusercontent.com/Polarisiu//proxy/main/CFDDNS.sh
        chmod +x "$DDNS_SCRIPT"
    fi

    # 默认配置
    cat <<'EOF' > "$CONFIG_FILE"
Domains=("your_domain1.com" "your_domain2.com")
ipv6_set="false"
Domainsv6=("your_domainv6_1.com" "your_domainv6_2.com")
Email="your_email@gmail.com"
Api_key="your_api_key"
Telegram_Bot_Token=""
Telegram_Chat_ID=""
Old_Public_IPv4=""
Old_Public_IPv6=""
EOF
    chmod +x "$CONFIG_FILE"
    echo -e "${Info}DDNS 安装完成！"
}

# ================== 配置 Cloudflare API ==================
set_cloudflare_api() {
    echo -e "${Tip}请输入您的Cloudflare邮箱:"
    read -rp "邮箱: " EMAIL
    [ -z "$EMAIL" ] && echo -e "${Error}邮箱不能为空" && return
    echo -e "${Tip}请输入Cloudflare API Key:"
    read -rp "密钥: " API_KEY
    [ -z "$API_KEY" ] && echo -e "${Error}API Key不能为空" && return
    sed -i "s|^Email=.*|Email=\"$EMAIL\"|" "$CONFIG_FILE"
    sed -i "s|^Api_key=.*|Api_key=\"$API_KEY\"|" "$CONFIG_FILE"
}

# ================== 配置域名 ==================
set_domain() {
    echo -e "${Tip}是否自动获取公网 IP？(y/n)"
    read -rp "选择: " auto_ip_choice
    if [[ "$auto_ip_choice" =~ ^[Yy]$ ]]; then
        get_public_ip
        sed -i "s|^Old_Public_IPv4=.*|Old_Public_IPv4=\"$Public_IPv4\"|" "$CONFIG_FILE"
        sed -i "s|^Old_Public_IPv6=.*|Old_Public_IPv6=\"$Public_IPv6\"|" "$CONFIG_FILE"
        echo -e "${Info}自动获取 IPv4: $Public_IPv4"
        echo -e "${Info}自动获取 IPv6: $Public_IPv6"
    else
        read -rp "手动输入 IPv4（可留空）: " manual_ipv4
        read -rp "手动输入 IPv6（可留空）: " manual_ipv6
        [ -n "$manual_ipv4" ] && sed -i "s|^Old_Public_IPv4=.*|Old_Public_IPv4=\"$manual_ipv4\"|" "$CONFIG_FILE"
        [ -n "$manual_ipv6" ] && sed -i "s|^Old_Public_IPv6=.*|Old_Public_IPv6=\"$manual_ipv6\"|" "$CONFIG_FILE"
    fi

    read -rp "请输入 IPv4 域名（可留空跳过）: " domains
    domains="${domains//，/,}"
    IFS=',' read -ra Domains <<< "$domains"
    sed -i '/^Domains=/c\Domains=('"${Domains[*]}"')' "$CONFIG_FILE"

    read -rp "请输入 IPv6 域名（可留空跳过）: " domainsv6
    domainsv6="${domainsv6//，/,}"
    IFS=',' read -ra Domainsv6 <<< "$domainsv6"
    sed -i '/^Domainsv6=/c\Domainsv6=('"${Domainsv6[*]}"')' "$CONFIG_FILE"
}

# ================== 配置 Telegram ==================
set_telegram_settings() {
    read -rp "请输入 Telegram Bot Token（可留空跳过）: " Token
    [ -n "$Token" ] && sed -i "s|^Telegram_Bot_Token=.*|Telegram_Bot_Token=\"$Token\"|" "$CONFIG_FILE"
    read -rp "请输入 Telegram Chat ID（可留空跳过）: " ChatID
    [ -n "$ChatID" ] && sed -i "s|^Telegram_Chat_ID=.*|Telegram_Chat_ID=\"$ChatID\"|" "$CONFIG_FILE"
}

# ================== 发送 Telegram 通知 ==================
send_telegram_notification() {
    source "$CONFIG_FILE"
    if [ -z "$Telegram_Bot_Token" ] || [ -z "$Telegram_Chat_ID" ]; then
        echo -e "${Error}Telegram Bot Token 或 Chat ID 未配置！"
        return
    fi

    get_public_ip

    msg="🌐 当前 DDNS 状态

"
    [ -n "$Public_IPv4" ] && msg+="🔹 IPv4: \`${Public_IPv4}\`
"
    [ -n "$Public_IPv6" ] && msg+="🔹 IPv6: \`${Public_IPv6}\`
"

    if [ "${#Domains[@]}" -gt 0 ]; then
        msg+="📄 IPv4 域名: ${Domains[*]}
"
    fi
    if [ "${#Domainsv6[@]}" -gt 0 ]; then
        msg+="📄 IPv6 域名: ${Domainsv6[*]}
"
    fi

    # 发送
    curl -s -X POST "https://api.telegram.org/bot${Telegram_Bot_Token}/sendMessage" \
         -d chat_id="$Telegram_Chat_ID" \
         -d parse_mode="Markdown" \
         -d text="$msg"
}





# ================== 运行 DDNS ==================
run_ddns() {
    if grep -qiE "alpine" /etc/os-release; then
        (crontab -l; echo "*/2 * * * * /bin/bash $DDNS_SCRIPT >/dev/null 2>&1") | crontab -
    else
        service='[Unit]
Description=ddns
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/DDNS
ExecStart=bash DDNS

[Install]
WantedBy=multi-user.target'

        timer='[Unit]
Description=ddns timer

[Timer]
OnUnitActiveSec=60s
Unit=ddns.service

[Install]
WantedBy=multi-user.target'

        echo "$service" >/etc/systemd/system/ddns.service
        echo "$timer" >/etc/systemd/system/ddns.timer
        systemctl enable --now ddns.service >/dev/null 2>&1
        systemctl enable --now ddns.timer >/dev/null 2>&1
    fi
    echo -e "${Info}DDNS 服务已启动！"
}

# ================== 停止 DDNS ==================
stop_ddns() {
    if grep -qiE "alpine" /etc/os-release; then
        crontab -l | grep -v "$DDNS_SCRIPT" | crontab -
    else
        systemctl stop ddns.service ddns.timer 2>/dev/null
    fi
    echo -e "${Info}DDNS 已停止！"
}

# ================== 显示当前状态 ==================
show_status() {
    echo -e "${GREEN}===== 当前 DDNS 状态 =====${NC}"
    get_public_ip
    echo -e "${Info}公网 IPv4: ${Public_IPv4}"
    echo -e "${Info}公网 IPv6: ${Public_IPv6}"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${Info}IPv4 域名: ${Domains[*]}"
        echo -e "${Info}IPv6 域名: ${Domainsv6[*]}"
        echo -e "${Info}Cloudflare 邮箱: $Email"
        echo -e "${Info}API Key: $Api_key"
        echo -e "${Info}Telegram Bot Token: $Telegram_Bot_Token"
        echo -e "${Info}Telegram Chat ID: $Telegram_Chat_ID"
    else
        echo -e "${Error}未找到配置文件！"
    fi
    echo -e "${GREEN}=============================${NC}"
    read -rp "按回车返回菜单..."
}

# ================== 显示菜单 ==================
menu() {
    while true; do
        show_title
        echo -e "${GREEN}1: 查看当前 DDNS 状态${NC}"
        echo -e "${GREEN}2: 重启 DDNS${NC}"
        echo -e "${GREEN}3: 停止 DDNS${NC}"
        echo -e "${GREEN}4: 卸载 DDNS${NC}"
        echo -e "${GREEN}5: 修改域名${NC}"
        echo -e "${GREEN}6: 修改 Cloudflare API${NC}"
        echo -e "${GREEN}7: 配置 Telegram 通知${NC}"
        echo -e "${GREEN}8: 修改 DDNS 运行时间${NC}"
        echo -e "${GREEN}9: 立即发送当前 IP 到 Telegram${NC}"
        echo -e "${GREEN}0: 退出${NC}"
        echo
        read -rp "选择: " option
        case "$option" in
            0) exit 0 ;;
            1) show_status ;;
            2) run_ddns ;;
            3) stop_ddns ;;
            4)
                rm -rf /etc/DDNS /usr/bin/ddns
                systemctl disable --now ddns.service ddns.timer 2>/dev/null
                echo -e "${Info}DDNS 已卸载！"
                read -rp "按回车返回菜单..."
                ;;
            5) set_domain ;;
            6) set_cloudflare_api ;;
            7) set_telegram_settings ;;
            8)
                read -rp "请输入新的运行间隔（分钟）: " interval
                if grep -qiE "alpine" /etc/os-release; then
                    (crontab -l | grep -v "$DDNS_SCRIPT"; echo "*/$interval * * * * /bin/bash $DDNS_SCRIPT >/dev/null 2>&1") | crontab -
                else
                    sed -i "s/OnUnitActiveSec=.*s/OnUnitActiveSec=${interval}m/" /etc/systemd/system/ddns.timer
                    systemctl daemon-reload
                    systemctl enable --now ddns.timer
                fi
                echo -e "${Info}运行间隔已修改为 ${interval} 分钟"
                read -rp "按回车返回菜单..."
                ;;
            9) send_telegram_notification ; read -rp "按回车返回菜单..." ;;
            *) echo -e "${Error}无效选项" ; read -rp "按回车返回菜单..." ;;
        esac
    done
}

# ================== 初始化 ==================
check_curl
if [ ! -f "$CONFIG_FILE" ]; then
    install_ddns
    set_cloudflare_api
    set_domain
    set_telegram_settings
    run_ddns
fi

menu
