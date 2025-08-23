#!/bin/bash
# ========================================
# 代理协议一键菜单
# 作者: 整合版
# 特点: 不安装依赖、15种协议、一键更新/卸载
# ========================================

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

SCRIPT_PATH="$HOME/proxy.sh"
SCRIPT_URL="https://raw.githubusercontent.com/Polarisiu/proxy/main/proxy.sh"  # 请替换成你自己的脚本地址

show_menu() {
    clear
    echo -e "${GREEN}========= 代理协议一键安装菜单 =========${RESET}"
    echo -e "${GREEN}当前时间: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${GREEN}[01] 老王 Sing-box 四合一${RESET}"
    echo -e "${GREEN}[02] 老王 Xray-2go 一键脚本${RESET}"
    echo -e "${GREEN}[03] mack-a 八合一脚本${RESET}"
    echo -e "${GREEN}[04] Hysteria2${RESET}"
    echo -e "${GREEN}[05] Tuic${RESET}"
    echo -e "${GREEN}[06] Reality${RESET}"
    echo -e "${GREEN}[07] 老王 Snell${RESET}"
    echo -e "${GREEN}[08] MTProto${RESET}"
    echo -e "${GREEN}[09] Anytls${RESET}"
    echo -e "${GREEN}[10] 3XUI管理${RESET}"
    echo -e "${GREEN}[11] MTProxy-Alpines${RESET}"
    echo -e "${GREEN}[12] GOST管理${RESET}"
    echo -e "${GREEN}[13] Realm管理${RESET}"
    echo -e "${GREEN}[14] Alpine转发${RESET}"
    echo -e "${GREEN}[15] FRP管理${RESET}"
    echo -e "${GREEN}[16] SS+SNELL${RESET}"
    echo -e "${GREEN}[17] Hysteria2(Alpines)${RESET}"
    echo -e "${GREEN}[18] S-UI面板${RESET}"
    echo -e "${GREEN}[19] H-UI面板${RESET}"
    echo -e "${GREEN}[20] OpenVPN安装${RESET}"
    
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${GREEN}[0]  退出脚本${RESET}"
    echo -e "${GREEN}========================================${RESET}"
}

install_protocol() {
    case "$1" in
        01|1) bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh) ;;
        02|2) bash <(curl -Ls https://github.com/eooce/xray-2go/raw/main/xray_2go.sh) ;;
        03|3) wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        04|4) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Hysteria2.sh) ;;
        05|5) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/tuic.sh) ;;
        06|6) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Reality.sh) ;;
        07|7) wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh ;;
        08|8) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/MTProto.sh) ;;
        09|9) bash <(curl -sL https://raw.githubusercontent.com/kirito201711/One-click-installation-of-anytls/main/install_anytls.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xui.sh) ;;
        11) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/dkmop.sh) ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/gost.sh) ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/Realm.sh) ;;
        14) curl -sS -O https://raw.githubusercontent.com/zyxinab/iptables-manager/main/iptables-manager.sh && chmod +x iptables-manager.sh && ./iptables-manager.sh ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/FRP.sh) ;;
        16) bash <(curl -L -s menu.jinqians.com) ;;
        17) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        18) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/s-ui.sh) ;;
        19) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/H-UI.sh) ;;
        20) install wget && wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh ;;
        88|088)
            echo -e "${GREEN}正在更新脚本...${RESET}"
            if curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
                chmod +x "$SCRIPT_PATH"
                echo -e "${GREEN}脚本已更新完成，正在重新加载...${RESET}"
                exec "$SCRIPT_PATH"
            else
                echo -e "${RED}更新失败，请检查网络或脚本地址！${RESET}"
            fi
            ;;
        99|099)
            echo -e "${RED}正在卸载脚本...${RESET}"
            rm -f "$SCRIPT_PATH"
            echo -e "${RED}脚本已卸载完成.${RESET}"
            exit 0
            ;;
        0)  echo -e "${GREEN}已退出脚本.${RESET}"; exit 0 ;;
        *)  echo -e "${RED}无效选项，请重新输入!${RESET}" ;;
    esac
}

# 主循环
while true; do
    show_menu
    read -p "请输入编号: " choice
    choice=$(echo "$choice" | tr -d '[:space:]')  # 去掉空格
    install_protocol "$choice"
    echo -e "\n${GREEN}按 Enter 返回菜单...${RESET}"
    read
done
