#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Numbered Interactive Installer
# =========================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║               CJH PANEL v4.5                 ║"
echo "║        Full Cloud Hosting Interface          ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Choose an option from the menu below:${NC}\n"
echo -e "  ${GREEN}[1]${NC} Install CJH Panel (Full Setup)"
echo -e "  ${GREEN}[2]${NC} Restart Panel Service"
echo -e "  ${GREEN}[3]${NC} View Panel Logs"
echo -e "  ${GREEN}[4]${NC} Exit Setup\n"

# Ensure terminal input stream works properly
exec < /dev/tty 2>/dev/null || true

read -p "Enter your choice [1-4]: " OPTION

case $OPTION in
    1)
        echo -e "\n${CYAN}=== ADMIN ACCOUNT SETUP ===${NC}"
        
        echo -e "\n${MAGENTA}--> Step 1: Type your desired Admin Username${NC}"
        read -p "Admin Username [default: admin]: " ADMIN_USER
        ADMIN_USER=${ADMIN_USER:-admin}

        echo -e "\n${MAGENTA}--> Step 2: Type your desired Admin Password${NC}"
        read -p "Admin Password [default: admin123]: " ADMIN_PASS
        ADMIN_PASS=${ADMIN_PASS:-admin123}

        echo -e "\n${MAGENTA}--> Step 3: Type Port Number for Web Panel${NC}"
        read -p "Panel Port [default: 6767]: " PORT
        PORT=${PORT:-6767}

        echo -e "\n${CYAN}[INFO] Saving Configurations...${NC}"

        # Save Config JSON
        cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

        # Save Package JSON
        cat <<EOF > package.json
{
  "name": "cjh-panel",
  "version": "4.5.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.6.1",
    "cors": "^2.8.5"
  }
}
EOF

        mkdir -p public

        echo -e "${CYAN}[INFO] Installing Node.js packages...${NC}"
        npm install --silent > /dev/null 2>&1

        echo -e "${GREEN}[SUCCESS] Setup completed! Launching server...${NC}"

        if command -v pm2 &> /dev/null; then
            pm2 delete cjh-panel 2>/dev/null || true
            pm2 start server.js --name "cjh-panel"
            pm2 save --force > /dev/null 2>&1 || true
        else
            node server.js &
        fi

        IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

        echo -e "\n${GREEN}=================================================="
        echo " CJH PANEL IS NOW ONLINE!"
        echo " Web Access : http://${IP}:${PORT}"
        echo " Admin User : ${ADMIN_USER}"
        echo " Admin Pass : ${ADMIN_PASS}"
        echo "==================================================${NC}\n"
        ;;
    2)
        echo -e "\n${CYAN}[INFO] Restarting CJH Panel...${NC}"
        if command -v pm2 &> /dev/null; then
            pm2 restart cjh-panel
        else
            pkill -f server.js || true
            node server.js &
        fi
        echo -e "${GREEN}[SUCCESS] Panel Restarted!${NC}"
        ;;
    3)
        echo -e "\n${CYAN}[INFO] Fetching Logs...${NC}"
        if command -v pm2 &> /dev/null; then
            pm2 logs cjh-panel --lines 20
        else
            echo "Logs are displayed in active node process."
        fi
        ;;
    4)
        echo -e "\n${YELLOW}Exiting installer.${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Invalid option selected. Exiting.${NC}"
        exit 1
        ;;
esac
