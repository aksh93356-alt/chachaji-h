#!/bin/bash
# =========================================================
# JTG / CJH MINECRAFT PANEL v5.0 - PREMIUM ENTERPRISE EDITION
# =========================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║          JTG MINECRAFT PANEL v5.0            ║"
echo "║        Premium Gaming Management System      ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

OPTION=$1

if [ -z "$OPTION" ]; then
    echo -e "${YELLOW}Choose an option:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Install/Update Panel Engine"
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
  "panel_name": "JTG PANEL"
}
EOF

        cat <<EOF > package.json
{
  "name": "jtg-mc-panel",
  "version": "5.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

        mkdir -p public

        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JTG PANEL - Minecraft Hosting System</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: #050505; color: #a1a1aa; height: 100vh; overflow: hidden; display: flex; }

        /* LOGIN VIEW */
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

        /* DEDICATED CONSOLE SCREEN */
        #console-view { display: none; width: 100vw; height: 100vh; background: #050505; flex-direction: row; }
        .console-sidebar { width: 220px; background: #09090b; border-right: 1px solid #18181b; padding: 1rem; display: flex; flex-direction: column; gap: 0.4rem; }
        .console-nav-title { color: #f4f4f5; font-weight: bold; margin-bottom: 1rem; display: flex; align-items: center; gap: 8px; font-size: 1rem; }
        .console-nav-item { padding: 0.6rem 0.8rem; font-size: 0.8rem; color: #71717a; border-radius: 4px; cursor: pointer; font-weight: 500; }
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
        .terminal-logs { flex: 1; padding: 1rem; font-family: monospace; font-size: 0.82rem; color: #22c55e; overflow-y: auto; line-height: 1.5; }
        .terminal-input { display: flex; background: #09090b; border-top: 1px solid #18181b; padding: 0.5rem; }
        .terminal-input input { flex: 1; background: transparent; border: none; outline: none; color: #fff; font-family: monospace; font-size: 0.85rem; padding: 0.3rem; }

        .stats-sidebar { width: 220px; display: flex; flex-direction: column; gap: 0.6rem; }
        .stat-card { background: #09090b; border: 1px solid #18181b; padding: 0.8rem; border-radius: 6px; }
        .stat-card .lbl { font-size: 0.7rem; color: #71717a; text-transform: uppercase; }
        .stat-card .val { font-size: 0.95rem; color: #f4f4f5; font-weight: bold; margin-top: 0.2rem; }

        .charts-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
        .chart-box { background: #09090b; border: 1px solid #18181b; border-radius: 6px; padding: 1rem; height: 140px; display: flex; flex-direction: column; justify-content: space-between; }
        .chart-visual { height: 60px; background: #18181b; border-radius: 4px; display: flex; align-items: flex-end; padding: 4px; gap: 4px; }
        .chart-bar { flex: 1; background: #6366f1; border-radius: 2px; transition: height 0.3s ease; }

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

    <!-- LOGIN SCREEN -->
    <div id="login-view">
        <div class="login-card">
            <h2 id="login-brand">JTG PANEL</h2>
            <p style="font-size:0.75rem; color:#71717a; margin-bottom:1.5rem;">MINECRAFT MANAGEMENT PANEL</p>
            <input type="text" id="u-input" placeholder="Username">
            <input type="password" id="p-input" placeholder="Password">
            <button onclick="handleLogin()">LOG IN</button>
        </div>
    </div>

    <!-- MAIN DASHBOARD -->
    <div id="app-view">
        <div class="sidebar">
            <div class="brand-header"><span>⚡</span> <span id="app-brand-name">JTG PANEL</span></div>
            <div class="nav-item active" onclick="showTab('overview', this)">Overview</div>
            <div class="nav-item" onclick="showTab('servers', this)">Servers</div>
            <div class="nav-item admin-only" onclick="showTab('nodes', this)">Nodes</div>
            <div class="nav-item admin-only" onclick="showTab('deploy', this)">+ Deploy</div>
            <div class="nav-item admin-only" onclick="showTab('fleet', this)">Fleet</div>
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
                    <h3>Built-in Node (Local System)</h3>
                    <p style="font-size:0.8rem; color:#71717a; margin-top:0.3rem;">CPU: <span id="node-cpu">12%</span> | RAM: <span id="node-ram">2.4 GB / 8 GB</span> | Disk: 14.2 GB / 50 GB</p>
                </div>
            </div>

            <!-- DEPLOY -->
            <div id="deploy" class="panel-section">
                <h1 class="sec-title">Deploy Minecraft Server</h1>
                <div class="card">
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">SERVER NAME</label>
                        <input type="text" id="dep-name" placeholder="e.g. Chachaji SMP" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                    </div>
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">ASSIGN USER</label>
                        <select id="dep-user" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;"></select>
                    </div>
                    <div style="margin-bottom:1rem;">
                        <label style="font-size:0.75rem; display:block; margin-bottom:0.3rem;">RAM ALLOCATION</label>
                        <select id="dep-ram" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                            <option value="2 GB">2 GB RAM</option>
                            <option value="4 GB">4 GB RAM</option>
                            <option value="8 GB">8 GB RAM</option>
                        </select>
                    </div>
                    <button class="btn-action btn-primary" onclick="deployServer()" style="width:100%; padding:0.75rem;">CREATE MINECRAFT INSTANCE</button>
                </div>
            </div>

            <!-- FLEET OPERATIONS -->
            <div id="fleet" class="panel-section">
                <h1 class="sec-title">Fleet & Resource Control</h1>
                <div class="card">
                    <h3>Server Allocation & Suspension Control</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Server Name</th>
                                <th>Owner</th>
                                <th>RAM</th>
                                <th>Status</th>
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
                        <input type="text" id="set-brand" value="JTG PANEL" style="width:100%; padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px; margin-top:0.3rem;">
                    </div>
                    <button class="btn-action btn-primary" onclick="saveSettings()">Save Global Settings</button>
                </div>
            </div>

            <!-- ACCOUNT MANAGEMENT -->
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
                    <h3>System Users List</h3>
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

    <!-- DEDICATED MINECRAFT CONSOLE SCREEN -->
    <div id="console-view">
        <div class="console-sidebar">
            <div class="console-nav-title">
                <span style="color:#818cf8;">●</span> <span id="mc-server-name">chachaji</span>
            </div>
            <div class="console-nav-item active">_ Terminal</div>
            <div class="console-nav-item">⚙ Properties</div>
            <div class="console-nav-item">📁 File Manager</div>
            <div class="console-nav-item">🔌 SFTP Details</div>
            <div class="console-nav-item">👥 Sub-Users</div>
            <div class="console-nav-item">🧩 Plugins</div>
            <div class="console-nav-item">🛠 Settings</div>
            <div class="console-nav-item">📦 Backup</div>
            <div class="console-nav-item">🌐 Playit Tunnel</div>
            
            <div style="margin-top:auto;" class="console-nav-item" onclick="closeConsoleView()">← Back to Dashboard</div>
        </div>

        <div class="console-main">
            <div class="console-topbar">
                <div>
                    <span style="font-size:0.75rem; color:#22c55e; font-weight:bold;" id="mc-status-indicator">● ONLINE</span>
                    <span style="font-size:0.75rem; color:#71717a; margin-left:8px;" id="mc-port-display">Port: 25565</span>
                </div>
                <div class="power-btns">
                    <button class="btn-pwr btn-start" onclick="mcPower('start')">▶ Start</button>
                    <button class="btn-pwr btn-restart" onclick="mcPower('restart')">⟳ Restart</button>
                    <button class="btn-pwr btn-stop" onclick="mcPower('stop')">■ Stop</button>
                </div>
            </div>

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
                        <div class="lbl">Server Address</div>
                        <div class="val" id="mc-ip">localhost:25565</div>
                    </div>
                    <div class="stat-card">
                        <div class="lbl">Uptime</div>
                        <div class="val" id="mc-uptime">02h 14m</div>
                    </div>
                    <div class="stat-card">
                        <div class="lbl">CPU Load</div>
                        <div class="val" id="mc-cpu">4.2%</div>
                    </div>
                    <div class="stat-card">
                        <div class="lbl">Memory</div>
                        <div class="val" id="mc-ram">1.8 GB / 4 GB</div>
                    </div>
                    <div class="stat-card">
                        <div class="lbl">Disk</div>
                        <div class="val">9.7 GB / 30 GB</div>
                    </div>
                </div>
            </div>

            <div class="charts-row">
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
    </div>

    <script>
        let loggedUser = null;

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
                loggedUser = data;
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

        async function loadData() {
            loadServers();
            loadUsers();
        }

        async function loadServers() {
            const res = await fetch('/api/servers');
            const servers = await res.json();

            let ovHtml = '', fleetHtml = '';
            servers.forEach((s, i) => {
                const statusColor = s.suspended ? '#ef4444' : '#22c55e';
                const statusText = s.suspended ? 'SUSPENDED' : 'ONLINE';

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

                fleetHtml += `
                    <tr>
                        <td><b>${s.name}</b></td>
                        <td>${s.owner}</td>
                        <td>${s.ram}</td>
                        <td><span style="color:${statusColor}; font-weight:bold;">${statusText}</span></td>
                        <td>
                            <button class="btn-action" onclick="toggleSuspend('${s.name}')">${s.suspended ? 'Unsuspend' : 'Suspend'}</button>
                            <button class="btn-action btn-danger" onclick="deleteServer('${s.name}')">Delete</button>
                        </td>
                    </tr>
                `;
            });

            document.getElementById('overview-server-list').innerHTML = ovHtml;
            document.getElementById('full-servers-list').innerHTML = ovHtml;
            document.getElementById('fleet-table-body').innerHTML = fleetHtml;
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
        }

        async function deployServer() {
            const name = document.getElementById('dep-name').value;
            const owner = document.getElementById('dep-user').value;
            const ram = document.getElementById('dep-ram').value;

            if(!name) return alert('Enter server name!');

            await fetch('/api/servers/create', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name, owner, ram, port: 25565 + Math.floor(Math.random()*1000) })
            });

            alert('Server Deployed!');
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

        /* CONSOLE SCREEN CONTROLS */
        function openConsoleView(name, port) {
            document.getElementById('app-view').style.display = 'none';
            document.getElementById('console-view').style.display = 'flex';
            document.getElementById('mc-server-name').innerText = name;
            document.getElementById('mc-port-display').innerText = 'Port: ' + port;
            document.getElementById('mc-ip').innerText = 'localhost:' + port;

            const logs = document.getElementById('mc-terminal-logs');
            logs.innerHTML = `
                [System] Loading server environment for [${name}]...<br>
                [Minecraft] Starting minecraft server version 1.20.1<br>
                [Minecraft] Loading properties and world files...<br>
                [Minecraft] Done (2.14s)! For help, type "help"<br>
            `;
        }

        function closeConsoleView() {
            document.getElementById('console-view').style.display = 'none';
            document.getElementById('app-view').style.display = 'flex';
        }

        function mcPower(action) {
            const logs = document.getElementById('mc-terminal-logs');
            if(action === 'start') logs.innerHTML += `<br>[SYSTEM] Server thread initiated. Starting...`;
            if(action === 'restart') logs.innerHTML += `<br>[SYSTEM] Server reboot triggered. Restarting...`;
            if(action === 'stop') logs.innerHTML += `<br>[SYSTEM] Stopping server process... Done.`;
            logs.scrollTop = logs.scrollHeight;
        }

        function handleMcCmd(e) {
            if (e.key === 'Enter') {
                const input = document.getElementById('mc-cmd-input');
                const logs = document.getElementById('mc-terminal-logs');
                logs.innerHTML += `<br><span style="color:#fff;">> ${input.value}</span>`;
                logs.innerHTML += `<br>[Server] Executed command: ${input.value}`;
                input.value = '';
                logs.scrollTop = logs.scrollHeight;
            }
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

                const cpuVal = (Math.random()*15 + 2).toFixed(1);
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

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

let config = { admin_user: "admin", admin_pass: "admin123", port: 6767, panel_name: "JTG PANEL" };
if (fs.existsSync('./config.json')) {
    try { config = JSON.parse(fs.readFileSync('./config.json')); } catch (e) {}
}

let servers = [
    { name: "chachaji", owner: "admin", ram: "4 GB", port: 25565, suspended: false }
];

let users = [
    { user: config.admin_user, pass: config.admin_pass, role: "Admin" },
    { user: "user", pass: "user123", role: "Member" }
];

app.post('/api/login', (req, res) => {
    const { user, pass } = req.body;
    const found = users.find(u => u.user === user && u.pass === pass);
    if (found) return res.json({ success: true, role: found.role, user: found.user });
    return res.json({ success: false });
});

app.get('/api/servers', (req, res) => res.json(servers));

app.post('/api/servers/create', (req, res) => {
    servers.push({ ...req.body, suspended: false });
    res.json({ success: true });
});

app.post('/api/servers/suspend', (req, res) => {
    const s = servers.find(item => item.name === req.body.name);
    if(s) s.suspended = !s.suspended;
    res.json({ success: true });
});

app.post('/api/servers/delete', (req, res) => {
    servers = servers.filter(item => item.name !== req.body.name);
    res.json({ success: true });
});

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
    console.log(` JTG MINECRAFT PANEL RUNNING ON PORT : ${PORT}`);
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
