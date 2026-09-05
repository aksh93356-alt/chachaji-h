#!/bin/bash
# =========================================================
# CJH PANEL v3.5 - Advanced Interactive Installer
# Credit: ZAIRA x Jishnu
# Supported: CodeSandbox Devbox & Linux VPS
# =========================================================

set -e

PANEL_NAME="CJH Panel"
DEFAULT_PORT="6767"
PLAYIT_VERSION="0.9.3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               CJH PANEL v3.5                 ║"
    echo "║        Automated Server Management           ║"
    echo "║             ZAIRA x Jishnu                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_deps() {
    log_info "Installing dependencies..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y -q > /dev/null 2>&1 || true
        sudo apt-get install -y curl git build-essential ca-certificates tar xz-utils unzip wget -q > /dev/null 2>&1 || true
    elif command -v yum &> /dev/null; then
        sudo yum update -y -q > /dev/null 2>&1 || true
        sudo yum install -y curl git make gcc-c++ ca-certificates tar xz unzip wget -q > /dev/null 2>&1 || true
    fi
}

install_playit() {
    log_info "Installing Playit.gg Tunnel Agent..."
    if ! command -v playit &> /dev/null; then
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) PLAYIT_ARCH="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) PLAYIT_ARCH="aarch64-unknown-linux-musl" ;;
            *) PLAYIT_ARCH="x86_64-unknown-linux-musl" ;;
        esac
        wget -q "https://github.com/playit-cloud/playit-agent/releases/download/v${PLAYIT_VERSION}/playit-${PLAYIT_ARCH}" -O /tmp/playit || true
        if [ -f "/tmp/playit" ]; then
            chmod +x /tmp/playit
            sudo mv /tmp/playit /usr/local/bin/playit 2>/dev/null || mv /tmp/playit ./playit
        fi
    fi
}

install_node() {
    log_info "Checking Node.js & PM2..."
    if ! command -v node &> /dev/null || [ "$(node -v | tr -d 'v' | cut -d'.' -f1)" -lt 18 ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1 || true
        sudo apt-get install -y nodejs > /dev/null 2>&1 || true
    fi
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2 > /dev/null 2>&1 || npm install pm2
    fi
}

setup_application() {
    echo -e "\n${YELLOW}=== ADMIN ACCOUNT & SETUP ===${NC}"
    
    # Read from terminal safely inside pipes
    exec < /dev/tty 2>/dev/null || true

    read -p "Enter Admin Username [default: admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    read -s -p "Enter Admin Password [default: admin123]: " ADMIN_PASS
    echo ""
    ADMIN_PASS=${ADMIN_PASS:-admin123}

    read -p "Enter Panel Port [default: 6767]: " PORT
    PORT=${PORT:-$DEFAULT_PORT}

    log_info "Generating files and web files..."
    mkdir -p .data/servers public plugins

    cat <<EOF > package.json
{
  "name": "cjh-panel",
  "version": "3.5.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.6.1",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2"
  }
}
EOF

    npm install --silent > /dev/null 2>&1

    cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

    cat <<'EOF' > server.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(express.json());
app.use(express.static('public'));

let config = { port: 6767, admin_user: "admin", admin_pass: "admin123" };
if (fs.existsSync('config.json')) {
    config = JSON.parse(fs.readFileSync('config.json'));
}

app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === config.admin_user && password === config.admin_pass) {
        res.json({ success: true, token: "cjh-authenticated-session" });
    } else {
        res.status(401).json({ success: false, message: "Invalid Admin Credentials" });
    }
});

app.post('/api/playit/setup', (req, res) => {
    exec('playit secret generate', (error, stdout) => {
        if (error) return res.status(500).json({ error: error.message });
        res.json({ output: stdout });
    });
});

io.on('connection', (socket) => {
    socket.emit('console-log', '[SYSTEM] Connected to CJH Panel Console.');

    socket.on('start-server', (data) => {
        const { serverPort } = data;
        socket.emit('console-log', `[SYSTEM] Initializing Game Server on Port ${serverPort}...`);
        
        const process = spawn('docker', ['run', '-i', '--rm', '-p', `${serverPort}:25565`, 'itzg/minecraft-server']);

        process.stdout?.on('data', (d) => socket.emit('console-log', d.toString()));
        process.stderr?.on('data', (d) => socket.emit('console-log', d.toString()));

        socket.on('command', (cmd) => {
            process.stdin?.write(cmd + "\n");
        });
    });
});

server.listen(config.port, '0.0.0.0', () => {
    console.log(`CJH Panel running on http://0.0.0.0:${config.port}`);
});
EOF

    cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJH Panel Dashboard v3.5</title>
    <style>
        body { background-color: #0d1117; color: #c9d1d9; font-family: system-ui, sans-serif; padding: 20px; margin: 0; }
        .container { max-width: 900px; margin: auto; }
        .card { background: #161b22; border: 1px solid #30363d; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        input, button { padding: 10px; margin: 5px 0; background: #21262d; border: 1px solid #30363d; color: #fff; border-radius: 5px; }
        button { background: #238636; cursor: pointer; font-weight: bold; border: none; }
        button:hover { background: #2ea043; }
        #console { background: #000; color: #3fb950; height: 280px; overflow-y: auto; padding: 10px; border-radius: 6px; font-family: monospace; border: 1px solid #30363d; }
    </style>
</head>
<body>
    <div class="container">
        <h1>CJH Panel v3.5 - Dashboard</h1>
        
        <div class="card">
            <h3>Server Controls</h3>
            <label>Port Assignment: </label>
            <input type="number" id="port" value="25565">
            <button onclick="startServer()">Start Game Server</button>
            <button onclick="setupTunnel()">Generate Playit Tunnel</button>
        </div>

        <div class="card">
            <h3>Live Game Console</h3>
            <div id="console"></div>
            <div style="display: flex; gap: 10px; margin-top: 10px;">
                <input type="text" id="cmd" placeholder="Type command here..." style="flex: 1;">
                <button onclick="sendCmd()">Send Command</button>
            </div>
        </div>
    </div>

    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const con = document.getElementById('console');

        socket.on('console-log', (msg) => {
            con.innerHTML += '<div>' + msg + '</div>';
            con.scrollTop = con.scrollHeight;
        });

        function startServer() {
            const p = document.getElementById('port').value;
            socket.emit('start-server', { serverPort: p });
        }

        function sendCmd() {
            const c = document.getElementById('cmd').value;
            socket.emit('command', c);
            document.getElementById('cmd').value = '';
        }

        function setupTunnel() {
            fetch('/api/playit/setup', { method: 'POST' })
            .then(res => res.json())
            .then(d => alert('Playit Link Response:\n' + JSON.stringify(d, null, 2)));
        }
    </script>
</body>
</html>
EOF
}

start_panel_service() {
    log_info "Starting Service via PM2 / Node..."
    if command -v pm2 &> /dev/null; then
        pm2 delete cjh-panel 2>/dev/null || true
        pm2 start server.js --name "cjh-panel"
        pm2 save --force > /dev/null 2>&1 || true
    else
        node server.js &
    fi
}

install_process() {
    print_banner
    check_deps
    install_playit
    install_node
    setup_application
    start_panel_service

    IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    log_success "CJH Panel installed and running!"
    echo -e "${GREEN}"
    echo "✓ Panel Web Link: http://${IP}:${PORT:-6767}"
    echo "✓ Check CodeSandbox 'PORTS' tab for the web preview link."
    echo "✓ Admin Username: ${ADMIN_USER:-admin}"
    echo -e "${NC}"
}

update_process() {
    print_banner
    log_info "Updating CJH Panel..."
    git pull origin main 2>/dev/null || git pull 2>/dev/null || true
    npm install --silent > /dev/null 2>&1
    start_panel_service
    log_success "CJH Panel updated successfully!"
}

# Auto-mode for Direct Commands (Auto Install)
if [ "$1" == "1" ] || [ "$1" == "install" ]; then
    install_process
    exit 0
elif [ "$1" == "2" ] || [ "$1" == "update" ]; then
    update_process
    exit 0
fi

# Main Interactive Menu
print_banner
echo -e "  ${BOLD}1)${NC} Panel Install"
echo -e "  ${BOLD}2)${NC} Panel Update"
echo ""

# Connect directly to terminal input stream
exec < /dev/tty 2>/dev/null || true
read -p " Choose an option (1-2): " OPTION

case "$OPTION" in
    1)
        install_process
        ;;
    2)
        update_process
        ;;
    *)
        log_error "Invalid Choice! Exiting..."
        exit 1
        ;;
esac
