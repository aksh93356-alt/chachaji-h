#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Interactive Installer
# Author: ZAIRA x Jishnu
# =========================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               CJH PANEL v4.5                 ║"
    echo "║        Full Cloud Hosting Interface          ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_banner

# Terminal input capture
exec < /dev/tty 2>/dev/null || true

echo -e "${YELLOW}=== ADMIN ACCOUNT SETUP ===${NC}"
read -p "Enter Admin Username [default: admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "Enter Admin Password [default: admin123]: " ADMIN_PASS
echo ""
ADMIN_PASS=${ADMIN_PASS:-admin123}

read -p "Enter Panel Port [default: 6767]: " PORT
PORT=${PORT:-6767}

echo -e "\n${CYAN}[INFO] Installing Dependencies & Setting up Package...${NC}"

# Package Configuration
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

# Credentials Configuration
cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

mkdir -p public

npm install --silent > /dev/null 2>&1

echo -e "${GREEN}[SUCCESS] Configuration saved successfully!${NC}"
echo -e "${CYAN}[INFO] Starting CJH Panel Service...${NC}"

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
echo " Web Access: http://${IP}:${PORT}"
echo " Admin User: ${ADMIN_USER}"
echo "==================================================${NC}\n"
