#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Full Interactive Admin Dashboard
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

        # 3. Create Public Folder & Interactive Login Dashboard
        mkdir -p public
        echo -e "${CYAN}[INFO] Creating Full Web UI Dashboard...${NC}"
        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CJH Panel v4.5</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background-color: #0b0f19; color: #e2e8f0; height: 100vh; display: flex; flex-direction: column; }
        
        /* LOGIN PAGE */
        #login-container { display: flex; justify-content: center; align-items: center; height: 100vh; width: 100%; }
        .login-box { background: #161e2e; padding: 2.5rem; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); width: 360px; text-align: center; border: 1px solid #2d3748; }
        .login-box h2 { color: #38bdf8; margin-bottom: 0.5rem; }
        .login-box p { color: #94a3b8; font-size: 0.85rem; margin-bottom: 1.5rem; }
        .input-group { margin-bottom: 1.2rem; text-align: left; }
        .input-group label { display: block; font-size: 0.8rem; color: #cbd5e1; margin-bottom: 0.3rem; }
        .input-group input { width: 100%; padding: 0.75rem; border-radius: 6px; border: 1px solid #334155; background: #0f172a; color: #fff; outline: none; }
        .btn-login { width: 100%; padding: 0.75rem; border: none; border-radius: 6px; background: #0284c7; color: white; font-weight: bold; cursor: pointer; transition: 0.2s; }
        .btn-login:hover { background: #0369a1; }
        .error-msg { color: #f87171; font-size: 0.85rem; margin-top: 1rem; display: none; }

        /* DASHBOARD PAGE */
        #dashboard-container { display: none; height: 100vh; flex-direction: row; }
        .sidebar { width: 240px; background: #111827; border-right: 1px solid #1f2937; padding: 1.5rem 1rem; display: flex; flex-direction: column; }
        .sidebar h2 { color: #38bdf8; font-size: 1.2rem; margin-bottom: 2rem; text-align: center; }
        .nav-btn { background: transparent; border: none; color: #9ca3af; padding: 0.8rem 1rem; text-align: left; font-size: 0.95rem; border-radius: 6px; cursor: pointer; margin-bottom: 0.5rem; width: 100%; transition: 0.2s; }
        .nav-btn.active, .nav-btn:hover { background: #1f2937; color: #38bdf8; font-weight: bold; }
        .logout-btn { margin-top: auto; background: #991b1b; color: white; }
        
        .main-content { flex: 1; padding: 2rem; overflow-y: auto; background: #0b0f19; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1f2937; padding-bottom: 1rem; margin-bottom: 1.5rem; }
        .header h1 { font-size: 1.5rem; color: #f3f4f6; }
        
        .tab-content { display: none; }
        .tab-content.active { display: block; }
        
        .card { background: #1f2937; padding: 1.5rem; border-radius: 8px; border: 1px solid #374151; margin-bottom: 1rem; }
        .console-box { background: #000; color: #4ade80; font-family: monospace; padding: 1rem; border-radius: 6px; height: 350px; overflow-y: auto; font-size: 0.9rem; }
    </style>
</head>
<body>

    <!-- LOGIN FORM -->
    <div id="login-container">
        <div class="login-box">
            <h2>CJH PANEL v4.5</h2>
            <p>Admin Login Required</p>
            <div class="input-group">
                <label>Username</label>
                <input type="text" id="username" placeholder="Enter username">
            </div>
            <div class="input-group">
                <label>Password</label>
                <input type="password" id="password" placeholder="Enter password">
            </div>
            <button class="btn-login" onclick="login()">Login to Dashboard</button>
            <p id="err-msg" class="error-msg">Invalid Username or Password!</p>
        </div>
    </div>

    <!-- MAIN DASHBOARD -->
    <div id="dashboard-container">
        <div class="sidebar">
            <h2>CJH PANEL</h2>
            <button class="nav-btn active" onclick="switchTab('my-server', this)">My Server</button>
            <button class="nav-btn" onclick="switchTab('console', this)">Console</button>
            <button class="nav-btn" onclick="switchTab('settings', this)">Settings</button>
            <button class="nav-btn logout-btn" onclick="logout()">Logout</button>
        </div>

        <div class="main-content">
            <div class="header">
                <h1 id="tab-title">My Server</h1>
                <span style="color: #4ade80; font-weight: bold;">● Online</span>
            </div>

            <!-- TAB 1: MY SERVER -->
            <div id="my-server" class="tab-content active">
                <div class="card">
                    <h3>Server Controls</h3>
                    <p style="margin-top: 0.5rem;">Manage your cloud instance actions below:</p>
                    <div style="margin-top: 1rem; display: flex; gap: 10px;">
                        <button style="padding: 0.6rem 1.2rem; background: #16a34a; border:none; color:white; border-radius:4px; cursor:pointer;" onclick="alert('Server Started!')">Start Server</button>
                        <button style="padding: 0.6rem 1.2rem; background: #dc2626; border:none; color:white; border-radius:4px; cursor:pointer;" onclick="alert('Server Stopped!')">Stop Server</button>
                        <button style="padding: 0.6rem 1.2rem; background: #d97706; border:none; color:white; border-radius:4px; cursor:pointer;" onclick="alert('Server Restarting...')">Restart</button>
                    </div>
                </div>
            </div>

            <!-- TAB 2: CONSOLE -->
            <div id="console" class="tab-content">
                <div class="card">
                    <h3>Realtime Console Output</h3>
                    <div class="console-box" id="console-logs">
                        [SYSTEM] CJH Panel Server Initialized...<br>
                        [SYSTEM] Node.js process running on active port.<br>
                        [AUTH] Admin user authenticated successfully.<br>
                        [STATUS] WebSockets connected. Ready for commands...
                    </div>
                </div>
            </div>

            <!-- TAB 3: SETTINGS -->
            <div id="settings" class="tab-content">
                <div class="card">
                    <h3>Panel Configuration Settings</h3>
                    <p style="margin-top: 0.5rem; color: #9ca3af;">Admin full control panel configurations.</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        async function login() {
            const user = document.getElementById('username').value;
            const pass = document.getElementById('password').value;
            
            const res = await fetch('/api/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ user, pass })
            });

            const data = await res.json();
            if(data.success) {
                document.getElementById('login-container').style.display = 'none';
                document.getElementById('dashboard-container').style.display = 'flex';
            } else {
                document.getElementById('err-msg').style.display = 'block';
            }
        }

        function switchTab(tabId, btn) {
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
            
            document.getElementById(tabId).classList.add('active');
            btn.classList.add('active');
            
            let title = "My Server";
            if(tabId === 'console') title = "Console";
            if(tabId === 'settings') title = "Settings";
            document.getElementById('tab-title').innerText = title;
        }

        function logout() {
            location.reload();
        }
    </script>
</body>
</html>
EOF

        # 4. Generate server.js with Login API Route
        echo -e "${CYAN}[INFO] Updating server.js with Login Authentication...${NC}"
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

app.post('/api/login', (req, res) => {
    const { user, pass } = req.body;
    if (user === config.admin_user && pass === config.admin_pass) {
        return res.json({ success: true, message: "Authenticated successfully" });
    }
    return res.json({ success: false, message: "Invalid credentials" });
});

const PORT = process.env.PORT || config.port || 6767;

server.listen(PORT, () => {
    console.log(`\n==================================================`);
    console.log(` CJH PANEL IS NOW RUNNING!`);
    console.log(` Web Server Port : ${PORT}`);
    console.log(`==================================================\n`);
});
EOF

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
