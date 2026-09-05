#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Auto Web UI & Server Installer
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

        # 1. Save Config JSON
        cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

        # 2. Save Package JSON
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

        # 3. Create Public Folder & index.html (Fix for Cannot GET /)
        mkdir -p public
        if [ ! -f "public/index.html" ]; then
            echo -e "${CYAN}[INFO] Creating Web Dashboard (public/index.html)...${NC}"
            cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CJH Panel v4.5</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #0f172a;
            color: #f8fafc;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background-color: #1e293b;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            text-align: center;
            width: 320px;
        }
        h1 { color: #38bdf8; margin-bottom: 0.5rem; }
        p { color: #94a3b8; font-size: 0.9rem; }
        .status {
            display: inline-block;
            margin-top: 1rem;
            padding: 0.5rem 1rem;
            background-color: #166534;
            color: #4ade80;
            border-radius: 4px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>CJH PANEL v4.5</h1>
        <p>Cloud Hosting Interface</p>
        <div class="status">System Online</div>
    </div>
</body>
</html>
EOF
        fi

        # 4. Generate server.js automatically
        if [ ! -f "server.js" ]; then
            echo -e "${CYAN}[INFO] Generating server.js entrypoint...${NC}"
            cat <<'EOF' > server.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

let config = { admin_user: "admin", admin_pass: "admin123", port: 6767 };
if (fs.existsSync('./config.json')) {
    try {
        config = JSON.parse(fs.readFileSync('./config.json'));
    } catch (e) {
        console.error("Error reading config.json", e);
    }
}

app.get('/api/status', (req, res) => {
    res.json({ status: "online", panel: "CJH Panel v4.5" });
});

const PORT = process.env.PORT || config.port || 6767;

server.listen(PORT, () => {
    console.log(`\n==================================================`);
    console.log(` CJH PANEL IS NOW RUNNING!`);
    console.log(` Web Server Port : ${PORT}`);
    console.log(`==================================================\n`);
});
EOF
        fi

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
