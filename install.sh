#!/bin/bash
# =========================================================
# CJH PANEL v4.5 - Advanced Role-Based Dashboard Setup
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
        echo -e "${CYAN}[INFO] Generating Role-Based UI Dashboard...${NC}"
        
        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JTG PANEL</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; }
        body { background-color: #050505; color: #a1a1aa; height: 100vh; display: flex; overflow: hidden; }
        
        /* LOGIN */
        #login-view { position: fixed; inset: 0; background: #050505; display: flex; align-items: center; justify-content: center; z-index: 100; }
        .login-card { background: #09090b; border: 1px solid #27272a; padding: 2rem; border-radius: 8px; width: 340px; text-align: center; }
        .login-card h2 { color: #f4f4f5; font-size: 1.5rem; letter-spacing: 2px; margin-bottom: 0.5rem; }
        .login-card input { width: 100%; padding: 0.6rem; margin: 0.5rem 0; background: #18181b; border: 1px solid #27272a; color: #fff; border-radius: 4px; outline: none; }
        .login-card button { width: 100%; padding: 0.6rem; background: #e11d48; border: none; color: white; font-weight: bold; border-radius: 4px; cursor: pointer; margin-top: 0.8rem; }

        /* MAIN WRAPPER */
        #app-view { display: none; width: 100vw; height: 100vh; }
        .sidebar { width: 220px; background: #09090b; border-right: 1px solid #18181b; padding: 1rem; display: flex; flex-direction: column; }
        .brand { color: #f4f4f5; font-weight: bold; letter-spacing: 1px; padding: 0.5rem; margin-bottom: 1.5rem; font-size: 1rem; }
        
        .nav-item { padding: 0.6rem 0.8rem; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 1px; color: #71717a; cursor: pointer; border-radius: 4px; margin-bottom: 0.2rem; display: flex; align-items: center; gap: 8px; }
        .nav-item:hover, .nav-item.active { background: #18181b; color: #f4f4f5; }
        
        .admin-only { display: none; } /* Hidden for Normal Users */
        
        .user-badge { margin-top: auto; padding: 0.8rem; background: #18181b; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
        .user-info { font-size: 0.75rem; color: #f4f4f5; font-weight: bold; }

        .content-area { flex: 1; background: #050505; padding: 2rem; overflow-y: auto; }
        .panel-section { display: none; }
        .panel-section.active { display: block; }
        
        h1.sec-title { color: #f4f4f5; font-size: 1.8rem; margin-bottom: 1rem; text-transform: uppercase; }
        .card { background: #09090b; border: 1px solid #18181b; padding: 1.5rem; border-radius: 6px; margin-bottom: 1rem; }
    </style>
</head>
<body>

    <!-- LOGIN OVERLAY -->
    <div id="login-view">
        <div class="login-card">
            <h2>JTG PANEL</h2>
            <p style="font-size:0.75rem; color:#71717a; margin-bottom:1rem;">ENTER CREDENTIALS</p>
            <input type="text" id="u-input" placeholder="Username">
            <input type="password" id="p-input" placeholder="Password">
            <button onclick="handleLogin()">ACCESS PANEL</button>
        </div>
    </div>

    <!-- MAIN APP INTERFACE -->
    <div id="app-view">
        <div class="sidebar">
            <div class="brand">⚡ JTG PANEL</div>
            
            <!-- ACCESSIBLE BY EVERYONE -->
            <div class="nav-item active" onclick="showTab('overview', this)">Overview</div>
            <div class="nav-item" onclick="showTab('servers', this)">Servers</div>

            <!-- ADMIN ONLY TABS -->
            <div class="nav-item admin-only" onclick="showTab('nodes', this)">Nodes</div>
            <div class="nav-item admin-only" onclick="showTab('deploy', this)">+ Deploy</div>
            <div class="nav-item admin-only" onclick="showTab('fleet', this)">Fleet</div>
            <div class="nav-item admin-only" onclick="showTab('apikeys', this)">API Keys</div>
            <div class="nav-item admin-only" onclick="showTab('admin-settings', this)">Admin Settings</div>

            <!-- ACCESSIBLE BY EVERYONE -->
            <div class="nav-item" onclick="showTab('account', this)">Account</div>

            <div class="user-badge">
                <div>
                    <div class="user-info" id="display-user">User</div>
                    <div style="font-size:0.65rem; color:#71717a;" id="display-role">Member</div>
                </div>
                <span style="cursor:pointer; color:#ef4444; font-size:0.8rem;" onclick="location.reload()">➔</span>
            </div>
        </div>

        <div class="content-area">
            <!-- OVERVIEW -->
            <div id="overview" class="panel-section active">
                <h1 class="sec-title">My Servers</h1>
                <div class="card">
                    <h3 style="color:#f4f4f5;">Active Instances</h3>
                    <p style="margin-top:0.5rem; font-size:0.85rem;">01 chachaji - [LOCAL SERVER ONLINE]</p>
                </div>
            </div>

            <!-- SERVERS -->
            <div id="servers" class="panel-section">
                <h1 class="sec-title">Servers List</h1>
                <div class="card"><p>Your assigned server instances will appear here.</p></div>
            </div>

            <!-- NODES (ADMIN ONLY) -->
            <div id="nodes" class="panel-section">
                <h1 class="sec-title">Nodes Monitor</h1>
                <div class="card"><p>Built-in Node (Local) - CPU: 0% | RAM: 19% | DISK: 47%</p></div>
            </div>

            <!-- DEPLOY (ADMIN ONLY) -->
            <div id="deploy" class="panel-section">
                <h1 class="sec-title">Deploy Server</h1>
                <div class="card"><p>Server deployment options and wizard.</p></div>
            </div>

            <!-- FLEET (ADMIN ONLY) -->
            <div id="fleet" class="panel-section">
                <h1 class="sec-title">Fleet Operations</h1>
                <div class="card"><p>Fleet metrics and node linking.</p></div>
            </div>

            <!-- API KEYS (ADMIN ONLY) -->
            <div id="apikeys" class="panel-section">
                <h1 class="sec-title">API Keys Management</h1>
                <div class="card"><p>Generate or invalidate developer API keys.</p></div>
            </div>

            <!-- ADMIN SETTINGS (ADMIN ONLY) -->
            <div id="admin-settings" class="panel-section">
                <h1 class="sec-title">Admin Settings</h1>
                <div class="card">
                    <h3 style="color:#f4f4f5; margin-bottom:0.5rem;">Branding & Panel Settings</h3>
                    <p style="font-size:0.85rem;">Full control features, theme appearance, and user management.</p>
                </div>
            </div>

            <!-- ACCOUNT -->
            <div id="account" class="panel-section">
                <h1 class="sec-title">Account Settings</h1>
                <div class="card"><p>Update user profile and password options.</p></div>
            </div>
        </div>
    </div>

    <script>
        async function handleLogin() {
            const user = document.getElementById('u-input').value;
            const pass = document.getElementById('p-input').value;

            const res = await fetch('/api/login', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ user, pass })
            });

            const data = await res.json();
            if (data.success) {
                document.getElementById('login-view').style.display = 'none';
                document.getElementById('app-view').style.display = 'flex';
                
                document.getElementById('display-user').innerText = user;
                document.getElementById('display-role').innerText = data.role;

                // Show Admin Controls ONLY if Role is Admin
                if (data.role === 'Admin') {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'flex');
                } else {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'none');
                }
            } else {
                alert('Invalid Credentials!');
            }
        }

        function showTab(tabId, btn) {
            document.querySelectorAll('.panel-section').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

            document.getElementById(tabId).classList.add('active');
            btn.classList.add('active');
        }
    </script>
</body>
</html>
EOF

        cat <<'EOF' > server.js
const express = require('express');
const http = require('http');
const cors = require('cors');
const fs = require('fs');

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

let config = { admin_user: "admin", admin_pass: "admin123", port: 6767 };
if (fs.existsSync('./config.json')) {
    try {
        config = JSON.parse(fs.readFileSync('./config.json'));
    } catch (e) {
        console.error("Config load error", e);
    }
}

app.post('/api/login', (req, res) => {
    const { user, pass } = req.body;
    
    // Check Admin Login
    if (user === config.admin_user && pass === config.admin_pass) {
        return res.json({ success: true, role: "Admin" });
    } 
    // Default Member Login Support
    else if (user === "user" && pass === "user123") {
        return res.json({ success: true, role: "Member" });
    }
    
    return res.json({ success: false, message: "Invalid credentials" });
});

const PORT = process.env.PORT || config.port || 6767;

server.listen(PORT, () => {
    console.log(`\n==================================================`);
    console.log(` JTG PANEL IS RUNNING ON PORT : ${PORT}`);
    console.log(`==================================================\n`);
});
EOF

        echo -e "${CYAN}[INFO] Installing dependencies...${NC}"
        npm install

        echo -e "\n${GREEN}=================================================="
        echo " CJH PANEL INSTALLED SUCCESSFULLY!"
        echo " Admin User  : ${ADMIN_USER}"
        echo " Admin Pass  : ${ADMIN_PASS}"
        echo " Member User : user"
        echo " Member Pass : user123"
        echo " Port        : ${PORT}"
        echo "==================================================${NC}\n"

        node server.js
        ;;
    2)
        pkill -f "node server.js" 2>/dev/null || true
        node server.js
        ;;
    3)
        echo -e "\n${CYAN}[INFO] Streaming server logs...${NC}"
        ;;
    4)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
