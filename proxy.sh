#!/bin/bash
# ========================================
# 代理协议一键菜单（首次运行自动执行，支持 W/w 快捷启动）
# 作者: 整合版
# 特点: 一键更新/卸载/快捷启动
# ========================================

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

SCRIPT_PATH="$HOME/proxy.sh"
SCRIPT_URL="https://raw.githubusercontent.com/Polarisiu/proxy/main/proxy.sh"
SHELL_RC="$HOME/.bashrc"  # 如果用 zsh，可改成 .zshrc

# 第一次运行，自动下载菜单脚本
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${GREEN}菜单脚本不存在，正在下载...${RESET}"
    if curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
        chmod +x "$SCRIPT_PATH"
        echo -e "${GREEN}下载完成: $SCRIPT_PATH${RESET}"
    else
        echo -e "${RED}下载失败，请检查网络或脚本地址！${RESET}"
        exit 1
    fi
fi

# 添加 W/w 快捷启动
if ! grep -q "alias W='bash \$HOME/proxy.sh'" "$SHELL_RC"; then
    echo -e "${GREEN}添加快捷键 W/w 到 $SHELL_RC${RESET}"
    echo "alias W='bash \$HOME/proxy.sh'" >> "$SHELL_RC"
    echo "alias w='bash \$HOME/proxy.sh'" >> "$SHELL_RC"
    echo -e "${GREEN}快捷键已添加，执行 'source $SHELL_RC' 或重新登录生效${RESET}"
fi

# 如果是首次运行，自动启动菜单
if [[ "$1" != "noauto" ]]; then
    exec bash "$SCRIPT_PATH" noauto
fi

# ================= 菜单逻辑 =================
show_menu() {
    clear
    echo -e "${GREEN}========= 代理协议一键安装菜单 =========${RESET}"
    echo -e "${GREEN}当前时间: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${GREEN}[01] 老王 Sing-box 四合一${RESET}"
    echo -e "${GREEN}[02] 老王 Xray-2go 一键脚本${RESET}"
    echo -e "${GREEN}[03] mack-a 八合一脚本${RESET}"
    echo -e "${GREEN}[04] Sing-box-yg${RESET}"
    echo -e "${GREEN}[05] Hysteria2${RESET}"
    echo -e "${GREEN}[06] Tuic${RESET}"
    echo -e "${GREEN}[07] Reality${RESET}"
    echo -e "${GREEN}[08] Snell${RESET}"
    echo -e "${GREEN}[09] MTProto${RESET}"
    echo -e "${GREEN}[10] Anytls${RESET}"
    echo -e "${GREEN}[11] 3XUI管理${RESET}"
    echo -e "${GREEN}[12] MTProxy(Docker)${RESET}"
    echo -e "${GREEN}[13] GOST管理${RESET}"
    echo -e "${GREEN}[14] Realm管理${RESET}"
    echo -e "${GREEN}[15] Alpine转发${RESET}"
    echo -e "${GREEN}[16] FRP管理${RESET}"
    echo -e "${GREEN}[17] SS+SNELL${RESET}"
    echo -e "${GREEN}[18] Hysteria2(Alpine)${RESET}"
    echo -e "${GREEN}[19] S-UI面板${RESET}"
    echo -e "${GREEN}[20] H-UI面板${RESET}"
    echo -e "${GREEN}[21] NodePass面板${RESET}"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${GREEN}[0]  退出脚本${RESET}"
    echo -e "${GREEN}快捷启动菜单: W 或 w${RESET}"
    echo -e "${GREEN}========================================${RESET}"
}

install_protocol() {
    case "$1" in
        01|1) bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh) ;;
        02|2) bash <(curl -Ls https://github.com/eooce/xray-2go/raw/main/xray_2go.sh) ;;
        03|3) wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        04|4) bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh) ;;
        05|5) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Hysteria2.sh) ;;
        06|6) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/tuicv5.sh) ;;
        07|7) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Reality.sh) ;;
        08|8) wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh ;;
        09|9) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/MTProto.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/anytls.sh) ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xui.sh) ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/dkmop.sh) ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/gost.sh) ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/Realm.sh) ;;
        15) curl -sS -O https://raw.githubusercontent.com/zyxinab/iptables-manager/main/iptables-manager.sh && chmod +x iptables-manager.sh && ./iptables-manager.sh ;;
        16) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/FRP.sh) ;;
        17) bash <(curl -L -s menu.jinqians.com) ;;
        18) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu//proxy/main/aphy2.sh) ;;
        19) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/s-ui.sh) ;;
        20) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/H-UI.sh) ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/NodePass.sh) ;;
        88|088)
            echo -e "${GREEN}正在更新脚本...${RESET}"
            if curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
                chmod +x "$SCRIPT_PATH"
                echo -e "${GREEN}脚本已更新完成，正在重新加载...${RESET}"
                exec "$SCRIPT_PATH" noauto
            else
                echo -e "${RED}更新失败，请检查网络或脚本地址！${RESET}"
            fi
            ;;
        99|099)
            echo -e "${RED}正在卸载脚本和快捷键...${RESET}"
            rm -f "$SCRIPT_PATH"
            sed -i "/alias W='bash \$HOME\/proxy.sh'/d" "$SHELL_RC"
            sed -i "/alias w='bash \$HOME\/proxy.sh'/d" "$SHELL_RC"
            echo -e "${RED}卸载完成，请重新登录使快捷键失效${RESET}"
            exit 0
            ;;
        0)  echo -e "${GREEN}已退出脚本.${RESET}"; exit 0 ;;
        *)  echo -e "${RED}无效选项，请重新输入!${RESET}" ;;
    esac
}

# 主循环
while true; do
    show_menu
    read -p "请输入编号或快捷键: " choice
    choice=$(echo "$choice" | tr -d '[:space:]')

    # W/w 快捷启动菜单
    if [[ "$choice" == "W" || "$choice" == "w" ]]; then
        bash "$SCRIPT_PATH" noauto
        continue
    fi

    install_protocol "$choice"
    echo -e "\n${GREEN}按 Enter 返回菜单...${RESET}"
    read
done
