#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "#     __                                   ____            "
echo "#    [  |  _                             .'    '.          "
echo "#     | | / ]   _   __   .--.   __   _  |  .--.  | _   __  "
echo "#     | '' <   [ \ [  ]/ .'\`\ \[  | | | | |    | |[ \ [  ] "
echo "#     | |\`\ \   \ '/ / | \__. | | \_/ |,|  \`--'  | > '  <  "
echo "#    [__|  \_][\_:  /   '.__.'  '.__.'_/ '.____.' [__]\`\_] "
echo "#              \__.'                                        "
echo ""
echo "============================================"
echo "   Discord Proxy Bypass - Uninstaller"
echo "============================================"
echo -e "${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Requesting administrator privileges...${NC}"
    exec sudo bash "$0" "$@"
    exit $?
fi

if [ -n "$SUDO_USER" ]; then
    REAL_USER=$SUDO_USER
    USER_HOME=$(eval echo ~${SUDO_USER})
else
    REAL_USER=$(whoami)
    USER_HOME=$HOME
fi

echo -e "${CYAN}[1/3] Removing proxy configurations...${NC}"

sed -i '/# Discord Proxy/d' "$USER_HOME/.bashrc"
sed -i '/export http_proxy/d' "$USER_HOME/.bashrc"
sed -i '/export https_proxy/d' "$USER_HOME/.bashrc"
sed -i '/export HTTP_PROXY/d' "$USER_HOME/.bashrc"
sed -i '/export HTTPS_PROXY/d' "$USER_HOME/.bashrc"

echo -e "${GREEN}  Proxy removed from ~/.bashrc${NC}"

echo -e "${CYAN}[2/3] Removing proxy from GNOME...${NC}"

if command -v gsettings &> /dev/null && [ -n "$REAL_USER" ]; then
    USER_ID=$(id -u ${REAL_USER})
    sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
        gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null || true
    echo -e "${GREEN}  Proxy removed from GNOME${NC}"
fi

echo -e "${CYAN}[3/3] Remove CA certificate? (Y/N)${NC}"
read -p "" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f /usr/local/share/ca-certificates/discord-proxy.crt
    update-ca-certificates --fresh > /dev/null 2>&1
    echo -e "${GREEN}  Certificate removed${NC}"
else
    echo -e "${YELLOW}  Certificate kept${NC}"
fi

echo ""
echo -e "${GREEN}Uninstallation complete!${NC}"
echo -e "${YELLOW}Restart terminal to apply changes${NC}"
echo ""
