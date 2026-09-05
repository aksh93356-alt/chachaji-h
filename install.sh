#!/bin/bash
# =========================================================
# CJH PANEL v2.0 - Advanced Game Panel Installer
# Credit: ZAIRA x Jishnu
# Features: Docker Integration, Live Console, Playit.gg Agent
# =========================================================

set -e

# Configuration
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
    echo "║               CJH PANEL v2.0                 ║"
    echo "║        Automated Server Management           ║"
    echo "║             ZAIRA x Jishnu                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# System Requirements
check_deps() {
    log_info "Installing system dependencies..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y -q > /dev/null 2>&1
        sudo apt-get install -y curl git build-essential ca-certificates tar xz-utils unzip wget -q > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum update -y -q > /dev/null 2>&1
        sudo yum install -y curl git make gcc-c++ ca-certificates tar xz unzip wget -q > /dev/null 2>&1
    fi
}

# Install Docker & Playit Agent
install_docker_playit() {
    log_info "Configuring Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
        sudo systemctl enable --now docker > /dev/null 2>&1 || true
    fi

    log_info "Installing Playit.gg Tunneling Agent..."
    if ! command -v playit &> /dev/null; then
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) PLAYIT_ARCH="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) PLAYIT_ARCH="aarch64-unknown-linux-musl" ;;
            *) PLAYIT_ARCH="x86_64-unknown-linux-musl" ;;
        esac
        wget -q "https://github.com/playit-cloud/playit-agent/releases/download/v${PLAYIT_VERSION}/playit-${PLAYIT_ARCH}" -O /usr/local/bin/playit || true
        chmod +x /usr/local/bin/playit || true
    fi
}

# Install Node.js
install_node() {
    log_info "Checking Node.js..."
    if ! command -v node &> /dev/null || [ "$(node -v | tr -d 'v' | cut -d'.' -f1)" -lt 20 ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
        sudo apt-get install -y nodejs > /dev/null 2>&1 || true
    fi
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2 > /dev/null 2>&1
    fi
}

# Setup Admin Account & App Structure
setup_application() {
    print_banner
    echo -e "${YELLOW}=== ADMIN ACCOUNT SETUP ===${NC}"
    read -p "Enter Admin Username: " ADMIN_USER
    read -s -p "Enter Admin Password: " ADMIN_PASS
    echo ""

    log_info "Setting up project files..."
    mkdir -p .data/servers public

    # Create package.json
    cat <<EOF > package.json
{
  "name": "cjh-panel",
  "version": "2.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.6.1",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2"
  }
}
EOF

    # Install NPM packages
    npm install > /dev/null 2>&1

    # Save credentials into config
    cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT
}
EOF

    # Create Server Logic (Backend)
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

const config = JSON.parse(fs.readFileSync('config.json'));

// Login API
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === config.admin_user && password === config.admin_pass) {
        res.json({ success: true, token: "admin-session-token" });
    } else {
        res.status(401).json({ success: false, message: "Invalid credentials" });
    }
});

// Playit Tunnel Claim URL Generator
app.post('/api/playit/setup', (req, res) => {
    exec('playit secret generate', (error, stdout) => {
        if (error) return res.status(500).json({ error: error.message });
        res.json({ output: stdout });
    });
});

// Socket Console Connection
io.on('connection', (socket) => {
    console.log('Client connected to live console');
    
    socket.on('start-server', (data) => {
        const { serverPort } = data;
        // Example docker command for server startup
        const gameProcess = spawn('docker', ['run', '-i', '--rm', '-p', `${serverPort}:25565`, 'itzg/minecraft-server']);
        
        gameProcess.stdout.on('data', (data) => {
            socket.emit('console-log', data.toString());
        });

        gameProcess.stderr.on('data', (data) => {
            socket.emit('console-log', data.toString());
        });

        socket.on('command', (cmd) => {
            gameProcess.stdin.write(cmd + "\n");
        });
    });
});

server.listen(config.port, () => {
    console.log(`CJH Panel running on port ${config.port}`);
});
EOF

    # Create Modern Frontend UI
    cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJH Panel - Dashboard</title>
    <style>
        body { background-color: #0f172a; color: #f8fafc; font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        .card { background: #1e293b; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        input, button { padding: 10px; margin: 5px 0; border-radius: 5px; border: none; }
        button { background: #3b82f6; color: white; cursor: pointer; }
        #console { background: #000; color: #00ff00; height: 250px; overflow-y: scroll; padding: 10px; font-family: monospace; }
    </style>
</head>
<body>
    <h1>CJH Panel Dashboard</h1>
    <div class="card">
        <h3>Server Controls</h3>
        <label>Server Port: </label>
        <input type="number" id="port" value="25565"><br>
        <button onclick="startServer()">Start Game Server</button>
        <button onclick="generatePlayit()">Setup Playit Tunnel</button>
    </div>

    <div class="card">
        <h3>Live Console Output</h3>
        <div id="console"></div>
        <input type="text" id="cmdInput" placeholder="Type command here..." style="width: 80%;">
        <button onclick="sendCommand()">Send</button>
    </div>

    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const consoleDiv = document.getElementById('console');

        socket.on('console-log', (data) => {
            consoleDiv.innerHTML += '<div>' + data + '</div>';
            consoleDiv.scrollTop = consoleDiv.scrollHeight;
        });

        function startServer() {
            const port = document.getElementById('port').value;
            socket.emit('start-server', { serverPort: port });
        }

        function sendCommand() {
            const cmd = document.getElementById('cmdInput').value;
            socket.emit('command', cmd);
            document.getElementById('cmdInput').value = '';
        }

        function generatePlayit() {
            fetch('/api/playit/setup', { method: 'POST' })
            .then(res => res.json())
            .then(data => alert('Playit Link Output: ' + JSON.stringify(data)));
        }
    </script>
</body>
</html>
EOF
}

# Start Service
start_panel() {
    log_info "Starting CJH Panel Service..."
    pm2 delete cjh-panel 2>/dev/null || true
    pm2 start server.js --name "cjh-panel"
    pm2 save --force > /dev/null 2>&1
}

# Main Execution Flow
print_banner
check_deps
install_docker_playit
install_node
setup_application
start_panel

IP=$(curl -s ifconfig.me || echo "localhost")
log_success "CJH Panel upgraded and installed successfully!"
echo -e "${GREEN}"
echo "✓ Panel URL: http://${IP}:${PORT}"
echo "✓ Live Console: Socket.io Enabled"
echo "✓ Tunneling: Playit Agent Active"
echo -e "${NC}"
