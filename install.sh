#!/bin/bash
# =========================================================
# CJH PANEL v3.0 - All-in-One Installer & Updater
# Credit: ZAIRA x Jishnu
# Environment: Linux VPS / CodeSandbox Devbox
# =========================================================

set -e

PANEL_NAME="CJH Panel"
PORT="6767"
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
    echo "║               CJH PANEL v3.0                 ║"
    echo "║        Automated Server Management           ║"
    echo "║             ZAIRA x Jishnu                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_deps() {
    log_info "Installing system dependencies..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y -q > /dev/null 2>&1 || true
        sudo apt-get install -y curl git build-essential ca-certificates tar xz-utils unzip wget -q > /dev/null 2>&1 || true
    elif command -v yum &> /dev/null; then
        sudo yum update -y -q > /dev/null 2>&1 || true
        sudo yum install -y curl git make gcc-c++ ca-certificates tar xz unzip wget -q > /dev/null 2>&1 || true
    fi
}

install_docker_playit() {
    log_info "Checking Docker Environment..."
    if command -v docker &> /dev/null; then
        sudo systemctl enable --now docker > /dev/null 2>&1 || true
    else
        log_info "Skipping Docker daemon auto-start (Containerized Environment Detected)."
    fi

    log_info "Installing Playit.gg Agent..."
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
    log_info "Checking Node.js..."
    if ! command -v node &> /dev/null || [ "$(node -v | tr -d 'v' | cut -d'.' -f1)" -lt 18 ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1 || true
        sudo apt-get install -y nodejs > /dev/null 2>&1 || true
    fi
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2 > /dev/null 2>&1 || npm install pm2
    fi
}

setup_application() {
    echo -e "\n${YELLOW}=== ADMIN ACCOUNT SETUP ===${NC}"
    read -p "Enter Admin Username: " ADMIN_USER
    read -s -p "Enter Admin Password: " ADMIN_PASS
    echo ""

    log_info "Creating Panel files and structure..."
    mkdir -p .data/servers public

    cat <<EOF > package.json
{
  "name": "cjh-panel",
  "version": "3.0.0",
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

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(express.json());
app.use(express.static('public'));

let config = { port: 6767, admin_user: "admin", admin_pass: "admin" };
if (fs.existsSync('config.json')) {
    config = JSON.parse(fs.readFileSync('config.json'));
}

app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === config.admin_user && password === config.admin_pass) {
        res.json({ success: true, token: "cjh-authenticated-session" });
    } else {
        res.status(401).json({ success: false, message: "Invalid credentials" });
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
        socket.emit('console-log', `[SYSTEM] Starting Server on Port ${serverPort}...`);
        
        const process = spawn('docker', ['run', '-i', '--rm', '-p', `${serverPort}:25565`, 'itzg/minecraft-server']);

        process.stdout?.on('data', (d) => socket.emit('console-log', d.toString()));
        process.stderr?.on('data', (d) => socket.emit('console-log', d.toString()));

        socket.on('command', (cmd) => {
            process.stdin?.write(cmd + "\n");
        });
    });
});

server.listen(config.port, '0.0.0.0', () => {
    console.log(`CJH Panel Running on Port ${config.port}`);
});
EOF

    cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJH Panel - Dashboard</title>
    <style>
        body { background-color: #0d1117; color: #c9d1d9; font-family: monospace; padding: 20px; }
        .card { background: #161b22; border: 1px solid #30363d; padding: 20px; border-radius: 6px; margin-bottom: 15px; }
        input, button { padding: 8px 12px; margin: 5px 0; background: #21262d; border: 1px solid #30363d; color: #fff; border-radius: 4px; }
        button { background: #238636; cursor: pointer; font-weight: bold; }
        #console { background: #000; color: #3fb950; height: 260px; overflow-y: auto; padding: 10px; border-radius: 4px; border: 1px solid #30363d; }
    </style>
</head>
<body>
    <h1>CJH Panel Dashboard v3.0</h1>
    <div class="card">
        <h3>Server Management</h3>
        <label>Server Port: </label>
        <input type="number" id="port" value="25565">
        <button onclick="startServer()">Start Game Server</button>
        <button onclick="setupTunnel()">Generate Playit Tunnel</button>
    </div>

    <div class="card">
        <h3>Live Server Console</h3>
        <div id="console"></div>
        <input type="text" id="cmd" placeholder="Enter command..." style="width: 75%;">
        <button onclick="sendCmd()">Send</button>
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
            .then(d => alert('Tunnel Response: ' + JSON.stringify(d)));
        }
    </script>
</body>
</html>
EOF
}

start_panel_service() {
    log_info "Starting Panel Service..."
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
    install_docker_playit
    install_node
    setup_application
    start_panel_service

    IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    log_success "CJH Panel installed successfully!"
    echo -e "${GREEN}"
    echo "✓ Web URL: http://${IP}:${PORT}"
    echo "✓ Active Port: ${PORT} (Check PORTS tab in CodeSandbox)"
    echo "✓ Live Console: Connected via Socket.io"
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

# Main Option Menu
print_banner
echo -e "  ${BOLD}1)${NC} Panel Install"
echo -e "  ${BOLD}2)${NC} Panel Update"
echo ""
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
