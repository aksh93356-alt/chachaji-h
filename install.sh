#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Auto Node/NPM Installer & Cloud Fix
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

OPTION=$1

if [ -z "$OPTION" ]; then
    echo -e "${YELLOW}Choose an option from the menu below:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Install CJH Panel (Full Setup)"
    echo -e "  ${GREEN}[2]${NC} Restart Panel Service"
    echo -e "  ${GREEN}[3]${NC} View Panel Logs"
    echo -e "  ${GREEN}[4]${NC} Exit Setup\n"

    if [ -t 0 ]; then
        read -p "Enter your choice [1-4]: " OPTION
    else
        read -p "Enter your choice [1-4]: " OPTION < /dev/tty || OPTION="1"
    fi
fi

case $OPTION in
    1)
        # ----------------------------------------------------
        # Node.js and NPM Environment Check & Auto-Install
        # ----------------------------------------------------
        if ! command -v npm &> /dev/null; then
            echo -e "${YELLOW}[WARN] Node.js/NPM not found. Installing Node.js automatically...${NC}"
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -y > /dev/null 2>&1 || true
                sudo apt-get install -y nodejs npm > /dev/null 2>&1 || true
            elif command -v yum &> /dev/null; then
                sudo yum install -y nodejs npm > /dev/null 2>&1 || true
            elif command -v apk &> /dev/null; then
                sudo apk add --no-cache nodejs npm > /dev/null 2>&1 || true
            fi
        fi

        # Re-check if npm is available after attempting auto-install
        if ! command -v npm &> /dev/null; then
            echo -e "${RED}[ERROR] Could not automatically install npm. Please install Node.js/npm manually in your environment.${NC}"
            exit 1
        fi

        echo -e "\n${CYAN}=== ADMIN ACCOUNT SETUP ===${NC}"

        get_input() {
            local prompt="$1"
            local default="$2"
            local var_name="$3"
            local user_val

            if [ -t 0 ]; then
                read -p "$prompt [default: $default]: " user_val
            else
                read -p "$prompt [default: $default]: " user_val < /dev/tty || user_val=""
            fi

            if [ -z "$user_val" ]; then
                eval "$var_name=\"$default\""
            else
                eval "$var_name=\"$user_val\""
            fi
        }

        echo -e "\n${MAGENTA}--> Step 1: Type your desired Admin Username${NC}"
        get_input "Admin Username" "admin" ADMIN_USER

        echo -e "\n${MAGENTA}--> Step 2: Type your desired Admin Password${NC}"
        get_input "Admin Password" "admin123" ADMIN_PASS

        echo -e "\n${MAGENTA}--> Step 3: Type Port Number for Web Panel${NC}"
        get_input "Panel Port" "6767" PORT

        echo -e "\n${CYAN}[INFO] Saving Configurations...${NC}"

        cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

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
        npm install

        echo -e "\n${GREEN}=================================================="
        echo " CJH PANEL INSTALLED SUCCESSFULLY!"
        echo " Admin User : ${ADMIN_USER}"
        echo " Admin Pass : ${ADMIN_PASS}"
        echo " Port       : ${PORT}"
        echo "==================================================${NC}\n"

        echo -e "${CYAN}[INFO] Starting CJH Panel server...${NC}"
        node server.js
        ;;
    2)
        echo -e "\n${CYAN}[INFO] Restarting CJH Panel...${NC}"
        pkill -f "node server.js" 2>/dev/null || true
        node server.js
        ;;
    3)
        echo -e "\n${CYAN}[INFO] Logs are streaming directly via Node process.${NC}"
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
