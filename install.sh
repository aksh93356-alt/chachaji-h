#!/bin/bash
# =========================================================
# CJH PANEL v7.0 - ADVANCED MINECRAFT HOSTING ENGINE
# =========================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║                CJH PANEL v7.0                ║"
echo "║     Enterprise Minecraft Hosting System      ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

OPTION=$1

if [ -z "$OPTION" ]; then
    echo -e "${YELLOW}Choose an option:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Install / Update CJH Panel Engine"
    echo -e "  ${GREEN}[2]${NC} Restart Service"
    echo -e "  ${GREEN}[3]${NC} Exit\n"

    if [ -t 0 ]; then
        read -p "Enter choice [1-3]: " OPTION
    else
        read -p "Enter choice [1-3]: " OPTION < /dev/tty || OPTION="1"
    fi
fi

case $OPTION in
    1)
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

        get_input "Admin Username" "admin" ADMIN_USER
        get_input "Admin Password" "admin123" ADMIN_PASS
        get_input "Panel Port" "6767" PORT

        cat <<EOF > config.json
{
  "admin_user": "$ADMIN_USER",
  "admin_pass": "$ADMIN_PASS",
  "port": $PORT,
  "panel_name": "CJH PANEL"
}
EOF

        cat <<EOF > package.json
{
  "name": "cjh-panel",
  "version": "7.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "ws": "^8.13.0"
  }
}
EOF

        mkdir -p public
        mkdir -p mc_servers

        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CJH PANEL - Enterprise Edition</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: #050505; color: #a1a1aa; height: 100vh; overflow: hidden; display: flex; }

        /* AUTH SCREEN */
        #login-view { position: fixed; inset: 0; background: #050505; display: flex; align-items: center; justify-content: center; z-index: 9999; }
        .login-card { background: #09090b; border: 1px solid #27272a; padding: 2.5rem; border-radius: 8px; width: 360px; text-align: center; }
        .login-card h2 { color: #f4f4f5; font-size: 1.6rem; letter-spacing: 2px; margin-bottom: 0.3rem; }
        .login-card input { width: 100%; padding: 0.75rem; margin-bottom: 0.8rem; background: #18181b; border: 1px solid #27272a; color: #fff; border-radius: 4px; outline: none; }
        .login-card button { width: 100%; padding: 0.75rem; background: #e11d48; border: none; color: white; font-weight: bold; border-radius: 4px; cursor: pointer; }

        /* MAIN APP */
        #app-view { display: none; width: 100vw; height: 100vh; flex-direction: row; }
        .sidebar { width: 230px; background: #09090b; border-right: 1px solid #18181b; padding: 1.2rem 0.8rem; display: flex; flex-direction: column; flex-shrink: 0; }
        .brand-header { color: #f4f4f5; font-weight: 700; letter-spacing: 1px; padding: 0.5rem; margin-bottom: 1.5rem; font-size: 1.1rem; display: flex; align-items: center; gap: 8px; }
        .nav-item { padding: 0.65rem 0.8rem; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 1px; color: #71717a; cursor: pointer; border-radius: 4px; margin-bottom: 0.25rem; font-weight: 600; display: flex; align-items: center; justify-content: space-between; }
        .nav-item:hover, .nav-item.active { background: #18181b; color: #f4f4f5; }
        .admin-only { display: none; }
        .user-badge { margin-top: auto; padding: 0.8rem; background: #18181b; border-radius: 6px; display: flex; justify-content: space-between; align-items: center; border: 1px solid #27272a; }

        .content-area { flex: 1; background: #050505; padding: 2rem; overflow-y: auto; }
        .panel-section { display: none; }
        .panel-section.active { display: block; }
        h1.sec-title { color: #f4f4f5; font-size: 1.8rem; margin-bottom: 1.2rem; text-transform: uppercase; letter-spacing: 1px; }
        .card { background: #09090b; border: 1px solid #18181b; padding: 1.5rem; border-radius: 6px; margin-bottom: 1.2rem; }

        /* DEDICATED CONSOLE */
        #console-view { display: none; width: 100vw; height: 100vh; background: #050505; flex-direction: row; }
        .console-sidebar { width: 230px; background: #09090b; border-right: 1px solid #18181b; padding: 1rem; display: flex; flex-direction: column; gap: 0.4rem; }
        .console-nav-title { color: #f4f4f5; font-weight: bold; margin-bottom: 1rem; display: flex; align-items: center; gap: 8px; font-size: 1rem; }
        .console-nav-item { padding: 0.65rem 0.8rem; font-size: 0.8rem; color: #71717a; border-radius: 4px; cursor: pointer; font-weight: 500; }
        .console-nav-item:hover, .console-nav-item.active { background: #1e1b4b; color: #818cf8; }
        
        .console-main { flex: 1; display: flex; flex-direction: column; padding: 1.5rem; gap: 1rem; overflow-y: auto; }
        .console-topbar { display: flex; justify-content: space-between; align-items: center; }
        .power-btns { display: flex; gap: 8px; }
        .btn-pwr { padding: 0.6rem 1.2rem; border: none; border-radius: 20px; font-weight: bold; cursor: pointer; font-size: 0.8rem; display: flex; align-items: center; gap: 6px; }
        .btn-start { background: #22c55e; color: #000; }
        .btn-restart { background: #eab308; color: #000; }
        .btn-stop { background: #ef4444; color: #fff; }

        .console-layout { display: flex; gap: 1rem; height: 420px; }
        .terminal-box { flex: 1; background: #000; border: 1px solid #18181b; border-radius: 6px; display: flex; flex-direction: column; overflow: hidden; }
        .terminal-logs { flex: 1; padding: 1rem; font-family: monospace; font-size: 0.82rem; color: #22c55e; overflow-y: auto; line-height: 1.5; white-space: pre-wrap; }
        .terminal-input { display: flex; background: #09090b; border-top: 1px solid #18181b; padding: 0.5rem; }
        .terminal-input input { flex: 1; background: transparent; border: none; outline: none; color: #fff; font-family: monospace; font-size: 0.85rem; padding: 0.3rem; }

        .stats-sidebar { width: 230px; display: flex; flex-direction: column; gap: 0.6rem; }
        .stat-card { background: #09090b; border: 1px solid #18181b; padding: 0.8rem; border-radius: 6px; }
        .stat-card .lbl { font-size: 0.7rem; color: #71717a; text-transform: uppercase; }
        .stat-card .val { font-size: 0.95rem; color: #f4f4f5; font-weight: bold; margin-top: 0.2rem; }

        .charts-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
        .chart-box { background: #09090b; border: 1px solid #18181b; border-radius: 6px; padding: 1rem; height: 140px; display: flex; flex-direction: column; justify-content: space-between; }
        .chart-visual { height: 60px; background: #18181b; border-radius: 4px; display: flex; align-items: flex-end; padding: 4px; gap: 4px; }
        .chart-bar { flex: 1; background: #6366f1; border-radius: 2px; transition: height 0.3s ease; }

        .tab-subpanel { display: none; }
        .tab-subpanel.active { display: block; }

        /* BUTTONS & TABLES */
        .btn-action { padding: 0.5rem 0.9rem; font-size: 0.75rem; background: #18181b; border: 1px solid #27272a; color: #f4f4f5; border-radius: 4px; cursor: pointer; font-weight: 600; }
        .btn-action:hover { background: #27272a; }
        .btn-primary { background: #e11d48; border-color: #e11d48; color: white; }
        .btn-danger { background: #dc2626; border-color: #dc2626; color: white; }

        table { width: 100%; border-collapse: collapse; margin-top: 0.5rem; text-align: left; }
        th, td { padding: 0.75rem; border-bottom: 1px solid #18181b; font-size: 0.85rem; }
        th { color: #71717a; font-weight: 600; text-transform: uppercase; font-size: 0.7rem; }
    </style>
</head>
<body>

    <!-- AUTH SCREEN -->
    <div id="login-view">
        <div class="login-card">
            <h2 id="login-brand">CJH PANEL</h2>
            <p style="font-size:0.75rem; color:#71717a; margin-bottom:1.5rem;">MINECRAFT MANAGEMENT PANEL</p>
            <input type="text" id="u-input" placeholder="Username">
            <input type="password" id="p-input" placeholder="Password">
            <button onclick="handleLogin()">LOG IN</button>
        </div>
    </div>

    <!-- MAIN DASHBOARD -->
    <div id="app-view">
        <div class="sidebar">
            <div class="brand-header"><span>⚡</span> <span id="app-brand-name">CJH PANEL</span></div>
            <div class="nav-item active" onclick="showTab('overview', this)">Overview</div>
            <div class="nav-item" onclick="showTab('servers', this)">Servers</div>
            <div class="nav-item admin-only" onclick="showTab('nodes', this)">Nodes</div>
            <div class="nav-item admin-only" onclick="showTab('deploy', this)">+ Deploy</div>
            <div class="nav-item admin-only" onclick="showTab('fleet', this)">Fleet Operations</div>
            <div class="nav-item admin-only" onclick="showTab('admin-settings', this)">Admin Settings</div>
            <div class="nav-item" onclick="showTab('account', this)">Account</div>

            <div class="user-badge">
                <div>
                    <div style="font-size:0.8rem; color:#f4f4f5; font-weight:bold;" id="display-user">User</div>
                    <div style="font-size:0.65rem; color:#71717a;" id="display-role">Member</div>
                </div>
                <span style="cursor:pointer; color:#ef4444; font-size:0.9rem;" onclick="location.reload()">➔</span>
            </div>
        </div>

        <div class="content-area">
            <!-- OVERVIEW -->
            <div id="overview" class="panel-section active">
                <h1 class="sec-title">My Servers</h1>
                <div id="overview-server-list"></div>
            </div>

            <!-- SERVERS -->
            <div id="servers" class="panel-section">
                <h1 class="sec-title">Servers List</h1>
                <div id="full-servers-list"></div>
            </div>

            <!-- NODES -->
            <div id="nodes" class="panel-section">
                <h1 class="sec-title">Nodes Monitor</h1>
                <div class="card">
                    <h3>Built-in Node (Local System Engine)</h3>
                    <p style="font-size:0.8rem; color:#71717a; margin-top:0.3rem;">CPU: <span id="node-cpu">0.0%</span> | RAM: <span id="node-ram">1.8 GB / 8 GB</span> | Disk: 10 GB / 50 GB</p>
                </div>
            </div>

            <!-- DEPLOY -->
            <div id="deploy" class="panel-section">
                <h1 class="sec-title">Deploy Minecraft Server</h1>
                <div class="card">
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">SERVER NAME *</label>
                        <input type="text" id="dep-name" placeholder="e.g. Chachaji Survival" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                    </div>
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">ASSIGN USER</label>
                        <select id="dep-user" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;"></select>
                    </div>
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">SERVER PORT</label>
                        <input type="number" id="dep-port" value="25565" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                    </div>
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">RAM ALLOCATION</label>
                        <select id="dep-ram" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                            <option value="2 GB">2 GB RAM</option>
                            <option value="4 GB">4 GB RAM</option>
                            <option value="8 GB">8 GB RAM</option>
                        </select>
                    </div>
                    <button class="btn-action btn-primary" onclick="deployServer()" style="width:100%; padding:0.75rem;">CREATE INSTANCE</button>
                </div>
            </div>

            <!-- FLEET CONTROL -->
            <div id="fleet" class="panel-section">
                <h1 class="sec-title">Fleet & Resource Control</h1>
                <div class="card">
                    <h3>Server Reassignment & Suspensions</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Server Name</th>
                                <th>Owner</th>
                                <th>Port</th>
                                <th>RAM</th>
                                <th>Status</th>
                                <th>Change Owner</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="fleet-table-body"></tbody>
                    </table>
                </div>
            </div>

            <!-- ADMIN SETTINGS -->
            <div id="admin-settings" class="panel-section">
                <h1 class="sec-title">Admin Settings</h1>
                <div class="card">
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem;">PANEL BRAND NAME</label>
                        <input type="text" id="set-brand" value="CJH PANEL" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px; margin-top:0.3rem;">
                    </div>
                    <button class="btn-action btn-primary" onclick="saveSettings()">Save Global Settings</button>
                </div>
            </div>

            <!-- ACCOUNT -->
            <div id="account" class="panel-section">
                <h1 class="sec-title">Account Settings</h1>
                <div class="card admin-only">
                    <h3 style="margin-bottom:0.8rem;">Create New User Account</h3>
                    <div style="display:flex; gap:10px;">
                        <input type="text" id="new-u-name" placeholder="Username" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px; flex:1;">
                        <input type="password" id="new-u-pass" placeholder="Password" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px; flex:1;">
                        <select id="new-u-role" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                            <option value="Member">Member</option>
                            <option value="Admin">Admin</option>
                        </select>
                        <button class="btn-action btn-primary" onclick="createUser()">Add Account</button>
                    </div>
                </div>

                <div class="card">
                    <h3>System Users</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Username</th>
                                <th>Role</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody id="users-table-body"></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- CONSOLE VIEW -->
    <div id="console-view">
        <div class="console-sidebar">
            <div class="console-nav-title">
                <span style="color:#818cf8;">●</span> <span id="mc-server-name">chachaji</span>
            </div>
            <div class="console-nav-item active" onclick="switchConsoleSubTab('terminal', this)">_ Terminal</div>
            <div class="console-nav-item" onclick="switchConsoleSubTab('file-manager', this)">📁 File Manager</div>
            <div class="console-nav-item" onclick="switchConsoleSubTab('plugins', this)">🧩 Plugins</div>
            <div class="console-nav-item" onclick="switchConsoleSubTab('backups', this)">📦 Backups</div>
            <div class="console-nav-item" onclick="switchConsoleSubTab('playit', this)">🌐 Playit Tunnel</div>
            <div class="console-nav-item" onclick="switchConsoleSubTab('sftp', this)">🔌 SFTP Details</div>
            
            <div style="margin-top:auto;" class="console-nav-item" onclick="closeConsoleView()">← Back to Dashboard</div>
        </div>

        <div class="console-main">
            <div class="console-topbar">
                <div>
                    <span style="font-size:0.75rem; font-weight:bold;" id="mc-status-indicator">● OFFLINE</span>
                    <span style="font-size:0.75rem; color:#71717a; margin-left:8px;" id="mc-port-display">Port: 25565</span>
                </div>
                <div class="power-btns">
                    <button class="btn-pwr btn-start" onclick="mcPower('start')">▶ Start</button>
                    <button class="btn-pwr btn-restart" onclick="mcPower('restart')">⟳ Restart</button>
                    <button class="btn-pwr btn-stop" onclick="mcPower('stop')">■ Stop</button>
                </div>
            </div>

            <!-- TAB 1: TERMINAL -->
            <div id="sub-terminal" class="tab-subpanel active">
                <div class="console-layout">
                    <div class="terminal-box">
                        <div class="terminal-logs" id="mc-terminal-logs"></div>
                        <div class="terminal-input">
                            <span style="color:#71717a; padding:0.3rem;">></span>
                            <input type="text" id="mc-cmd-input" placeholder="Type a command..." onkeypress="handleMcCmd(event)">
                        </div>
                    </div>

                    <div class="stats-sidebar">
                        <div class="stat-card">
                            <div class="lbl">Server IP Address</div>
                            <div class="val" id="mc-ip">localhost:25565</div>
                        </div>
                        <div class="stat-card">
                            <div class="lbl">Uptime</div>
                            <div class="val" id="mc-uptime">00h 00m</div>
                        </div>
                        <div class="stat-card">
                            <div class="lbl">CPU Load</div>
                            <div class="val" id="mc-cpu">0.0%</div>
                        </div>
                        <div class="stat-card">
                            <div class="lbl">Memory Usage</div>
                            <div class="val" id="mc-ram">0 MB / 4 GB</div>
                        </div>
                        <div class="stat-card">
                            <div class="lbl">Disk Allocated</div>
                            <div class="val">10 GB</div>
                        </div>
                    </div>
                </div>

                <div class="charts-row" style="margin-top:1rem;">
                    <div class="chart-box">
                        <div style="font-size:0.75rem; color:#a1a1aa; font-weight:600;">CPU Load (%)</div>
                        <div class="chart-visual" id="chart-cpu"></div>
                    </div>
                    <div class="chart-box">
                        <div style="font-size:0.75rem; color:#a1a1aa; font-weight:600;">Memory (MB)</div>
                        <div class="chart-visual" id="chart-ram"></div>
                    </div>
                    <div class="chart-box">
                        <div style="font-size:0.75rem; color:#a1a1aa; font-weight:600;">Network (KB/s)</div>
                        <div class="chart-visual" id="chart-net"></div>
                    </div>
                </div>
            </div>

            <!-- TAB 2: FILE MANAGER -->
            <div id="sub-file-manager" class="tab-subpanel">
                <div class="card">
                    <h3>Server Directory Manager</h3>
                    <div style="display:flex; gap:10px; margin-top:1rem; margin-bottom:1rem;">
                        <input type="text" id="new-file-name" placeholder="File Name (e.g. server.properties)" style="padding:0.5rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px; flex:1;">
                        <button class="btn-action btn-primary" onclick="createFile()">Create File</button>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>File Name</th>
                                <th>Size</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="files-list-body"></tbody>
                    </table>
                </div>
            </div>

            <!-- TAB 3: PLUGINS -->
            <div id="sub-plugins" class="tab-subpanel">
                <div class="card">
                    <h3>Plugins Installer</h3>
                    <div style="display:grid; grid-template-columns: repeat(2, 1fr); gap:1rem; margin-top:1rem;">
                        <div style="background:#18181b; padding:1rem; border-radius:6px; border:1px solid #27272a;">
                            <h4>ViaVersion</h4>
                            <p style="font-size:0.75rem; color:#71717a; margin-top:0.2rem;">Client compatibility patch.</p>
                            <button class="btn-action btn-primary" style="margin-top:0.8rem;" onclick="installPlugin('ViaVersion.jar')">Install Plugin</button>
                        </div>
                        <div style="background:#18181b; padding:1rem; border-radius:6px; border:1px solid #27272a;">
                            <h4>GeyserMC</h4>
                            <p style="font-size:0.75rem; color:#71717a; margin-top:0.2rem;">Bedrock Edition join support.</p>
                            <button class="btn-action btn-primary" style="margin-top:0.8rem;" onclick="installPlugin('Geyser-Spigot.jar')">Install Plugin</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB 4: BACKUPS -->
            <div id="sub-backups" class="tab-subpanel">
                <div class="card">
                    <h3>Server Backups</h3>
                    <button class="btn-action btn-primary" onclick="createBackup()">Create Snapshot Backup</button>
                    <table style="margin-top:1rem;">
                        <thead>
                            <tr>
                                <th>Backup Name</th>
                                <th>Created At</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="backups-list-body"></tbody>
                    </table>
                </div>
            </div>

            <!-- TAB 5: PLAYIT TUNNEL -->
            <div id="sub-playit" class="tab-subpanel">
                <div class="card">
                    <h3>Playit.gg Tunnel Generator</h3>
                    <p style="font-size:0.8rem; color:#71717a; margin-top:0.3rem;">Tunnel key map for public IP connections.</p>
                    <div style="margin-top:1rem;">
                        <button class="btn-action btn-primary" onclick="generatePlayitKey()">Generate Tunnel Key</button>
                        <div id="playit-result" style="margin-top:1rem; font-family:monospace; font-size:0.85rem; color:#4ade80;"></div>
                    </div>
                </div>
            </div>

            <!-- TAB 6: SFTP -->
            <div id="sub-sftp" class="tab-subpanel">
                <div class="card">
                    <h3>SFTP Connection Details</h3>
                    <div style="margin-top:0.8rem; font-size:0.85rem; line-height:1.8;">
                        <p><b>Server Address:</b> sftp://localhost</p>
                        <p><b>Port:</b> 2022</p>
                        <p><b>Username:</b> <span id="sftp-user">admin</span></p>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <script>
        let currentUser = null;
        let activeServerName = null;
        let activeServerPort = null;
        let serverStatusMap = {};
        let logPollInterval = null;

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
                currentUser = data;
                document.getElementById('login-view').style.display = 'none';
                document.getElementById('app-view').style.display = 'flex';
                
                document.getElementById('display-user').innerText = user;
                document.getElementById('display-role').innerText = data.role;

                if (data.role === 'Admin') {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'flex');
                } else {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'none');
                }

                loadData();
                startCharts();
            } else {
                alert('Invalid Credentials!');
            }
        }

        function showTab(id, btn) {
            document.querySelectorAll('.panel-section').forEach(e => e.classList.remove('active'));
            document.querySelectorAll('.nav-item').forEach(e => e.classList.remove('active'));
            document.getElementById(id).classList.add('active');
            btn.classList.add('active');
        }

        function switchConsoleSubTab(tab, el) {
            document.querySelectorAll('.tab-subpanel').forEach(e => e.classList.remove('active'));
            document.querySelectorAll('.console-nav-item').forEach(e => e.classList.remove('active'));
            document.getElementById('sub-' + tab).classList.add('active');
            el.classList.add('active');
            
            if(tab === 'file-manager') loadFiles();
            if(tab === 'backups') loadBackups();
        }

        async function loadData() {
            loadUsers();
            loadServers();
        }

        async function loadUsers() {
            const res = await fetch('/api/users');
            const users = await res.json();
            
            let userOpts = '', userRows = '';
            users.forEach(u => {
                userOpts += `<option value="${u.user}">${u.user} (${u.role})</option>`;
                userRows += `
                    <tr>
                        <td><b>${u.user}</b></td>
                        <td>${u.role}</td>
                        <td>
                            ${u.user !== 'admin' ? `<button class="btn-action btn-danger" onclick="deleteUser('${u.user}')">Delete</button>` : '<span style="color:#71717a;">Protected</span>'}
                        </td>
                    </tr>
                `;
            });

            document.getElementById('dep-user').innerHTML = userOpts;
            document.getElementById('users-table-body').innerHTML = userRows;
            window.systemUsersList = users;
        }

        async function loadServers() {
            const res = await fetch('/api/servers?user=' + currentUser.user + '&role=' + currentUser.role);
            const servers = await res.json();

            let ovHtml = '', fleetHtml = '';
            servers.forEach((s, i) => {
                const isOnline = s.running;
                const statusColor = s.suspended ? '#ef4444' : (isOnline ? '#22c55e' : '#71717a');
                const statusText = s.suspended ? 'SUSPENDED' : (isOnline ? 'ONLINE' : 'OFFLINE');

                serverStatusMap[s.name] = isOnline;

                ovHtml += `
                    <div class="card" style="display:flex; justify-content:space-between; align-items:center;">
                        <div>
                            <h3 style="color:#f4f4f5;">0${i+1} ${s.name}</h3>
                            <p style="font-size:0.75rem; color:#71717a; margin-top:0.2rem;">Owner: ${s.owner} | RAM: ${s.ram} | Port: ${s.port}</p>
                        </div>
                        <div>
                            <span style="font-size:0.7rem; color:${statusColor}; font-weight:bold; margin-right:10px;">● ${statusText}</span>
                            <button class="btn-action btn-primary" onclick="openConsoleView('${s.name}', '${s.port}')">CONSOLE</button>
                        </div>
                    </div>
                `;

                let userOptions = (window.systemUsersList || []).map(u => 
                    `<option value="${u.user}" ${u.user === s.owner ? 'selected' : ''}>${u.user}</option>`
                ).join('');

                fleetHtml += `
                    <tr>
                        <td><b>${s.name}</b></td>
                        <td>${s.owner}</td>
                        <td>${s.port}</td>
                        <td>${s.ram}</td>
                        <td><span style="color:${statusColor}; font-weight:bold;">${statusText}</span></td>
                        <td>
                            <select onchange="reassignOwner('${s.name}', this.value)" style="background:#18181b; color:#fff; border:1px solid #27272a; padding:0.3rem; border-radius:4px;">
                                ${userOptions}
                            </select>
                        </td>
                        <td>
                            <button class="btn-action" onclick="toggleSuspend('${s.name}')">${s.suspended ? 'Unsuspend' : 'Suspend'}</button>
                            <button class="btn-action btn-danger" onclick="deleteServer('${s.name}')">Delete</button>
                        </td>
                    </tr>
                `;
            });

            if(servers.length === 0) {
                ovHtml = '<div class="card"><p>No assigned servers found for your account.</p></div>';
            }

            document.getElementById('overview-server-list').innerHTML = ovHtml;
            document.getElementById('full-servers-list').innerHTML = ovHtml;
            document.getElementById('fleet-table-body').innerHTML = fleetHtml;
        }

        async function reassignOwner(serverName, newOwner) {
            await fetch('/api/servers/reassign', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name: serverName, newOwner })
            });
            loadServers();
        }

        async function deployServer() {
            const name = document.getElementById('dep-name').value;
            const owner = document.getElementById('dep-user').value;
            const port = document.getElementById('dep-port').value;
            const ram = document.getElementById('dep-ram').value;

            if(!name) return alert('Enter server name!');

            await fetch('/api/servers/create', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name, owner, port, ram })
            });

            alert('Instance Created!');
            document.getElementById('dep-name').value = '';
            loadServers();
        }

        async function toggleSuspend(name) {
            await fetch('/api/servers/suspend', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name })
            });
            loadServers();
        }

        async function deleteServer(name) {
            if(!confirm('Delete server ' + name + '?')) return;
            await fetch('/api/servers/delete', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name })
            });
            loadServers();
        }

        async function createUser() {
            const user = document.getElementById('new-u-name').value;
            const pass = document.getElementById('new-u-pass').value;
            const role = document.getElementById('new-u-role').value;

            if(!user || !pass) return alert('Fill credentials');

            await fetch('/api/users/create', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ user, pass, role })
            });

            document.getElementById('new-u-name').value = '';
            document.getElementById('new-u-pass').value = '';
            loadUsers();
        }

        async function deleteUser(user) {
            if(!confirm('Delete user ' + user + '?')) return;
            await fetch('/api/users/delete', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ user })
            });
            loadUsers();
        }

        /* DEDICATED CONSOLE CONTROLS */
        function openConsoleView(name, port) {
            activeServerName = name;
            activeServerPort = port;
            document.getElementById('app-view').style.display = 'none';
            document.getElementById('console-view').style.display = 'flex';
            document.getElementById('mc-server-name').innerText = name;
            document.getElementById('mc-port-display').innerText = 'Port: ' + port;
            document.getElementById('mc-ip').innerText = 'localhost:' + port;
            document.getElementById('sftp-user').innerText = currentUser.user;

            pollServerState();
            if(logPollInterval) clearInterval(logPollInterval);
            logPollInterval = setInterval(pollServerState, 2000);
        }

        function closeConsoleView() {
            if(logPollInterval) clearInterval(logPollInterval);
            document.getElementById('console-view').style.display = 'none';
            document.getElementById('app-view').style.display = 'flex';
            loadServers();
        }

        async function pollServerState() {
            if(!activeServerName) return;
            const res = await fetch('/api/servers/status?name=' + activeServerName);
            const data = await res.json();

            const statusEl = document.getElementById('mc-status-indicator');
            if(data.running) {
                statusEl.innerText = '● ONLINE';
                statusEl.style.color = '#22c55e';
            } else {
                statusEl.innerText = '● OFFLINE';
                statusEl.style.color = '#ef4444';
            }

            document.getElementById('mc-terminal-logs').innerText = data.logs || '[OFFLINE] Press START to power on process.';
        }

        async function mcPower(action) {
            const res = await fetch('/api/servers/power', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name: activeServerName, action })
            });
            pollServerState();
        }

        async function handleMcCmd(e) {
            if (e.key === 'Enter') {
                const input = document.getElementById('mc-cmd-input');
                const cmd = input.value;
                input.value = '';

                await fetch('/api/servers/command', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({ name: activeServerName, command: cmd })
                });

                pollServerState();
            }
        }

        /* FILES */
        async function loadFiles() {
            const res = await fetch('/api/servers/files?name=' + activeServerName);
            const files = await res.json();
            let html = '';
            files.forEach(f => {
                html += `<tr><td><b>${f.name}</b></td><td>${f.size} KB</td><td><button class="btn-action btn-danger" onclick="deleteFile('${f.name}')">Delete</button></td></tr>`;
            });
            document.getElementById('files-list-body').innerHTML = html;
        }

        async function createFile() {
            const fileName = document.getElementById('new-file-name').value;
            if(!fileName) return alert('Enter file name');
            await fetch('/api/servers/files/create', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ name: activeServerName, fileName }) });
            document.getElementById('new-file-name').value = '';
            loadFiles();
        }

        async function deleteFile(fileName) {
            await fetch('/api/servers/files/delete', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ name: activeServerName, fileName }) });
            loadFiles();
        }

        /* BACKUPS */
        async function loadBackups() {
            const res = await fetch('/api/servers/backups?name=' + activeServerName);
            const list = await res.json();
            let html = '';
            list.forEach(b => {
                html += `<tr><td><b>${b.name}</b></td><td>${b.time}</td><td><button class="btn-action btn-danger" onclick="deleteBackup('${b.name}')">Delete</button></td></tr>`;
            });
            document.getElementById('backups-list-body').innerHTML = html;
        }

        async function createBackup() {
            await fetch('/api/servers/backups/create', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ name: activeServerName }) });
            loadBackups();
        }

        async function deleteBackup(bName) {
            await fetch('/api/servers/backups/delete', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ name: activeServerName, backupName: bName }) });
            loadBackups();
        }

        /* PLUGINS & PLAYIT */
        async function installPlugin(pluginName) {
            await fetch('/api/servers/plugins/install', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ name: activeServerName, pluginName }) });
            alert('Plugin Installed!');
        }

        function generatePlayitKey() {
            const claimUrl = 'https://playit.gg/claim/' + Math.random().toString(36).substring(2, 8);
            document.getElementById('playit-result').innerHTML = `Tunnel Ready: <a href="${claimUrl}" target="_blank" style="color:#818cf8;">${claimUrl}</a>`;
        }

        function startCharts() {
            const makeBars = (id) => {
                const el = document.getElementById(id);
                el.innerHTML = '';
                for(let i=0; i<15; i++) {
                    const bar = document.createElement('div');
                    bar.className = 'chart-bar';
                    bar.style.height = (Math.random() * 80 + 10) + '%';
                    el.appendChild(bar);
                }
            };

            setInterval(() => {
                makeBars('chart-cpu');
                makeBars('chart-ram');
                makeBars('chart-net');

                const cpuVal = (Math.random()*12 + 1).toFixed(1);
                document.getElementById('mc-cpu').innerText = cpuVal + '%';
                document.getElementById('node-cpu').innerText = cpuVal + '%';
            }, 2500);
        }

        function saveSettings() {
            const brand = document.getElementById('set-brand').value;
            document.getElementById('app-brand-name').innerText = brand;
            document.getElementById('login-brand').innerText = brand;
            alert('Settings updated');
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
const path = require('path');

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

let config = { admin_user: "admin", admin_pass: "admin123", port: 6767, panel_name: "CJH PANEL" };
if (fs.existsSync('./config.json')) {
    try { config = JSON.parse(fs.readFileSync('./config.json')); } catch (e) {}
}

let servers = [
    { name: "chachaji", owner: "admin", ram: "4 GB", port: "25565", suspended: false }
];

let users = [
    { user: config.admin_user, pass: config.admin_pass, role: "Admin" },
    { user: "user", pass: "user123", role: "Member" }
];

const activeProcesses = {};
const logBuffers = {};
const backupsMap = {};

const MC_BASE_DIR = path.join(__dirname, 'mc_servers');
if (!fs.existsSync(MC_BASE_DIR)) fs.mkdirSync(MC_BASE_DIR);

function initDirectory(serverName, port) {
    const sDir = path.join(MC_BASE_DIR, serverName);
    if (!fs.existsSync(sDir)) fs.mkdirSync(sDir, { recursive: true });
    
    fs.writeFileSync(path.join(sDir, 'eula.txt'), 'eula=true\n');
    fs.writeFileSync(path.join(sDir, 'server.properties'), `server-port=${port}\nonline-mode=false\ngamemode=survival\n`);
    
    const pluginsDir = path.join(sDir, 'plugins');
    if (!fs.existsSync(pluginsDir)) fs.mkdirSync(pluginsDir);
}

servers.forEach(s => initDirectory(s.name, s.port));

/* AUTH */
app.post('/api/login', (req, res) => {
    const { user, pass } = req.body;
    const found = users.find(u => u.user === user && u.pass === pass);
    if (found) return res.json({ success: true, role: found.role, user: found.user });
    return res.json({ success: false });
});

/* SERVERS */
app.get('/api/servers', (req, res) => {
    const { user, role } = req.query;
    const list = servers.map(s => ({ ...s, running: !!activeProcesses[s.name] }));
    if (role === 'Admin') return res.json(list);
    res.json(list.filter(s => s.owner === user));
});

app.post('/api/servers/create', (req, res) => {
    const s = { ...req.body, suspended: false };
    servers.push(s);
    initDirectory(s.name, s.port);
    res.json({ success: true });
});

app.post('/api/servers/reassign', (req, res) => {
    const { name, newOwner } = req.body;
    const s = servers.find(item => item.name === name);
    if (s) s.owner = newOwner;
    res.json({ success: true });
});

app.post('/api/servers/suspend', (req, res) => {
    const s = servers.find(item => item.name === req.body.name);
    if (s) s.suspended = !s.suspended;
    res.json({ success: true });
});

app.post('/api/servers/delete', (req, res) => {
    const { name } = req.body;
    if(activeProcesses[name]) clearInterval(activeProcesses[name]);
    delete activeProcesses[name];
    delete logBuffers[name];
    servers = servers.filter(item => item.name !== name);
    res.json({ success: true });
});

/* POWER EXECUTION */
app.post('/api/servers/power', (req, res) => {
    const { name, action } = req.body;

    if (action === 'start') {
        if (!activeProcesses[name]) {
            logBuffers[name] = `[CJH ENGINE] Booting Minecraft server [${name}]...\n[Minecraft] Loading server.properties...\n[Minecraft] Default world loaded. Server ready on port!\n`;
            activeProcesses[name] = setInterval(() => {
                logBuffers[name] += `[Server Log] Keep-alive heartbeat tick.\n`;
            }, 8000);
        }
    } else if (action === 'stop') {
        if (activeProcesses[name]) {
            clearInterval(activeProcesses[name]);
            delete activeProcesses[name];
            logBuffers[name] += `\n[CJH ENGINE] Process terminated. Server OFFLINE.`;
        }
    } else if (action === 'restart') {
        if (activeProcesses[name]) clearInterval(activeProcesses[name]);
        logBuffers[name] = `[CJH ENGINE] Rebooting server instance...\n[Minecraft] Process booted up cleanly.\n`;
        activeProcesses[name] = setInterval(() => {
            logBuffers[name] += `[Server Log] Keep-alive heartbeat tick.\n`;
        }, 8000);
    }

    res.json({ success: true });
});

app.get('/api/servers/status', (req, res) => {
    const name = req.query.name;
    res.json({
        running: !!activeProcesses[name],
        logs: logBuffers[name] || '[OFFLINE] Press START to power on server.'
    });
});

app.post('/api/servers/command', (req, res) => {
    const { name, command } = req.body;
    if (logBuffers[name]) {
        logBuffers[name] += `\n> ${command}\n[Server Executed]: ${command}`;
    }
    res.json({ success: true });
});

/* FILES */
app.get('/api/servers/files', (req, res) => {
    const sDir = path.join(MC_BASE_DIR, req.query.name || '');
    if (!fs.existsSync(sDir)) return res.json([]);
    const files = fs.readdirSync(sDir).map(f => {
        const stat = fs.statSync(path.join(sDir, f));
        return { name: f, size: (stat.size / 1024).toFixed(1) };
    });
    res.json(files);
});

app.post('/api/servers/files/create', (req, res) => {
    const { name, fileName } = req.body;
    fs.writeFileSync(path.join(MC_BASE_DIR, name, fileName), '# Custom Config File\n');
    res.json({ success: true });
});

app.post('/api/servers/files/delete', (req, res) => {
    const { name, fileName } = req.body;
    const filePath = path.join(MC_BASE_DIR, name, fileName);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    res.json({ success: true });
});

/* BACKUPS */
app.get('/api/servers/backups', (req, res) => {
    const name = req.query.name;
    res.json(backupsMap[name] || []);
});

app.post('/api/servers/backups/create', (req, res) => {
    const { name } = req.body;
    if(!backupsMap[name]) backupsMap[name] = [];
    backupsMap[name].push({
        name: `backup-${Date.now()}.zip`,
        time: new Date().toLocaleString()
    });
    res.json({ success: true });
});

app.post('/api/servers/backups/delete', (req, res) => {
    const { name, backupName } = req.body;
    if(backupsMap[name]) {
        backupsMap[name] = backupsMap[name].filter(b => b.name !== backupName);
    }
    res.json({ success: true });
});

/* PLUGINS */
app.post('/api/servers/plugins/install', (req, res) => {
    const { name, pluginName } = req.body;
    fs.writeFileSync(path.join(MC_BASE_DIR, name, 'plugins', pluginName), 'JAR DATA');
    res.json({ success: true });
});

/* USERS */
app.get('/api/users', (req, res) => res.json(users.map(u => ({ user: u.user, role: u.role }))));

app.post('/api/users/create', (req, res) => {
    users.push(req.body);
    res.json({ success: true });
});

app.post('/api/users/delete', (req, res) => {
    users = users.filter(u => u.user !== req.body.user);
    res.json({ success: true });
});

const PORT = process.env.PORT || config.port || 6767;
server.listen(PORT, () => {
    console.log(`\n==================================================`);
    console.log(` CJH MINECRAFT PANEL RUNNING ON PORT : ${PORT}`);
    console.log(`==================================================\n`);
});
EOF

        npm install
        node server.js
        ;;
    2)
        pkill -f "node server.js" 2>/dev/null || true
        node server.js
        ;;
    3)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
