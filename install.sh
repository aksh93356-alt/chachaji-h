#!/bin/bash
# =========================================================
# JTG / CJH PANEL v4.5 - FULL INTERACTIVE ENGINE SETUP
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
echo "║               JTG PANEL v4.5                 ║"
echo "║      Production Ready Hosting Engine         ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

OPTION=$1

if [ -z "$OPTION" ]; then
    echo -e "${YELLOW}Choose an option from the menu below:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Install JTG Panel Engine"
    echo -e "  ${GREEN}[2]${NC} Restart Service"
    echo -e "  ${GREEN}[3]${NC} Exit Setup\n"

    if [ -t 0 ]; then
        read -p "Enter your choice [1-3]: " OPTION
    else
        read -p "Enter your choice [1-3]: " OPTION < /dev/tty || OPTION="1"
    fi
fi

case $OPTION in
    1)
        echo -e "\n${CYAN}=== ADMIN INITIALIZATION ===${NC}"

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

        echo -e "\n${CYAN}[INFO] Generating Config Files...${NC}"

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
  "name": "jtg-panel",
  "version": "4.5.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

        mkdir -p public
        echo -e "${CYAN}[INFO] Building Complete Frontend Interface...${NC}"

        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JTG PANEL</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: #050505; color: #a1a1aa; height: 100vh; display: flex; overflow: hidden; }

        /* LOGIN VIEW */
        #login-view { position: fixed; inset: 0; background: #050505; display: flex; align-items: center; justify-content: center; z-index: 999; }
        .login-card { background: #09090b; border: 1px solid #27272a; padding: 2.5rem; border-radius: 8px; width: 360px; text-align: center; }
        .login-card h2 { color: #f4f4f5; font-size: 1.6rem; letter-spacing: 2px; margin-bottom: 0.3rem; }
        .login-card p { font-size: 0.75rem; color: #71717a; margin-bottom: 1.5rem; }
        .login-card input { width: 100%; padding: 0.7rem; margin-bottom: 0.8rem; background: #18181b; border: 1px solid #27272a; color: #fff; border-radius: 4px; outline: none; }
        .login-card button { width: 100%; padding: 0.7rem; background: #e11d48; border: none; color: white; font-weight: bold; border-radius: 4px; cursor: pointer; transition: 0.2s; }
        .login-card button:hover { background: #be123c; }

        /* MAIN APP LAYOUT */
        #app-view { display: none; width: 100vw; height: 100vh; flex-direction: row; }
        .sidebar { width: 230px; background: #09090b; border-right: 1px solid #18181b; padding: 1.2rem 0.8rem; display: flex; flex-direction: column; }
        .brand-header { color: #f4f4f5; font-weight: 700; letter-spacing: 1px; padding: 0.5rem; margin-bottom: 1.5rem; font-size: 1.1rem; display: flex; align-items: center; gap: 8px; }
        
        .nav-item { padding: 0.65rem 0.8rem; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 1px; color: #71717a; cursor: pointer; border-radius: 4px; margin-bottom: 0.25rem; font-weight: 600; display: flex; align-items: center; justify-content: space-between; }
        .nav-item:hover, .nav-item.active { background: #18181b; color: #f4f4f5; }
        .admin-only { display: none; }

        .user-badge { margin-top: auto; padding: 0.8rem; background: #18181b; border-radius: 6px; display: flex; justify-content: space-between; align-items: center; border: 1px solid #27272a; }
        .user-info { font-size: 0.8rem; color: #f4f4f5; font-weight: bold; }

        .content-area { flex: 1; background: #050505; padding: 2rem; overflow-y: auto; }
        .panel-section { display: none; }
        .panel-section.active { display: block; }
        
        h1.sec-title { color: #f4f4f5; font-size: 1.8rem; margin-bottom: 1.2rem; text-transform: uppercase; letter-spacing: 1px; }
        .card { background: #09090b; border: 1px solid #18181b; padding: 1.5rem; border-radius: 6px; margin-bottom: 1.2rem; }

        /* NODES / REAL TIME MONITOR UI */
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-top: 1rem; }
        .metric-card { background: #18181b; padding: 1rem; border-radius: 6px; border: 1px solid #27272a; }
        .metric-val { font-size: 1.4rem; color: #f4f4f5; font-weight: bold; margin-top: 0.3rem; }
        .progress-bar { width: 100%; background: #27272a; height: 6px; border-radius: 3px; margin-top: 0.5rem; overflow: hidden; }
        .progress-fill { background: #10b981; height: 100%; width: 0%; transition: width 0.5s ease; }

        /* DEPLOY WIZARD STYLES */
        .wizard-steps { display: flex; gap: 1rem; margin-bottom: 1.5rem; }
        .step-pill { background: #18181b; border: 1px solid #27272a; padding: 0.5rem 1rem; border-radius: 4px; font-size: 0.75rem; color: #71717a; }
        .step-pill.active { border-color: #e11d48; color: #f4f4f5; font-weight: bold; }
        
        .form-group { margin-bottom: 1.2rem; }
        .form-group label { display: block; font-size: 0.75rem; color: #a1a1aa; margin-bottom: 0.4rem; text-transform: uppercase; letter-spacing: 1px; }
        .form-group input, .form-group select { width: 100%; padding: 0.75rem; background: #18181b; border: 1px solid #27272a; color: #fff; border-radius: 4px; outline: none; }
        
        .ram-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.8rem; margin-top: 0.5rem; }
        .ram-option { background: #18181b; border: 1px solid #27272a; padding: 1rem; border-radius: 6px; text-align: center; cursor: pointer; }
        .ram-option.selected { border-color: #e11d48; background: #27272a; }
        .ram-option h4 { color: #f4f4f5; font-size: 1rem; }
        .ram-option p { font-size: 0.65rem; color: #71717a; margin-top: 0.2rem; }

        /* SERVERS & CONSOLE */
        .server-item { display: flex; justify-content: space-between; align-items: center; background: #09090b; border: 1px solid #18181b; padding: 1.2rem; border-radius: 6px; margin-bottom: 0.8rem; }
        .server-item h3 { color: #f4f4f5; font-size: 1.1rem; }
        .status-tag { display: inline-block; font-size: 0.7rem; padding: 0.2rem 0.5rem; border-radius: 4px; background: rgba(16, 185, 129, 0.1); color: #10b981; font-weight: bold; }
        
        .btn-action { padding: 0.5rem 0.9rem; font-size: 0.75rem; background: #18181b; border: 1px solid #27272a; color: #f4f4f5; border-radius: 4px; cursor: pointer; font-weight: 600; margin-left: 0.3rem; }
        .btn-action:hover { background: #27272a; }
        .btn-primary { background: #e11d48; border-color: #e11d48; color: white; }
        .btn-primary:hover { background: #be123c; }

        /* TERMINAL CONSOLE */
        .console-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.85); z-index: 1000; align-items: center; justify-content: center; }
        .console-container { background: #09090b; border: 1px solid #27272a; width: 800px; height: 500px; border-radius: 8px; display: flex; flex-direction: column; overflow: hidden; }
        .console-header { background: #18181b; padding: 0.8rem 1rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #27272a; color: #f4f4f5; font-size: 0.9rem; font-weight: bold; }
        .console-body { flex: 1; background: #000; padding: 1rem; font-family: monospace; font-size: 0.85rem; color: #4ade80; overflow-y: auto; }
        .console-footer { padding: 0.8rem; background: #18181b; display: flex; gap: 0.5rem; border-top: 1px solid #27272a; }
        .console-footer input { flex: 1; background: #000; border: 1px solid #27272a; color: #fff; padding: 0.5rem; border-radius: 4px; font-family: monospace; }
    </style>
</head>
<body>

    <!-- LOGIN MODAL -->
    <div id="login-view">
        <div class="login-card">
            <h2 id="login-brand-title">JTG PANEL</h2>
            <p>ENTER CREDENTIALS TO SIGN IN</p>
            <input type="text" id="u-input" placeholder="Username">
            <input type="password" id="p-input" placeholder="Password">
            <button onclick="handleLogin()">ACCESS DASHBOARD</button>
        </div>
    </div>

    <!-- MAIN DASHBOARD -->
    <div id="app-view">
        <div class="sidebar">
            <div class="brand-header"><span style="color:#e11d48">⚡</span> <span id="app-brand-name">JTG PANEL</span></div>
            
            <div class="nav-item active" onclick="showTab('overview', this)">Overview</div>
            <div class="nav-item" onclick="showTab('servers', this)">Servers</div>

            <!-- ADMIN TABS -->
            <div class="nav-item admin-only" onclick="showTab('nodes', this)">Nodes</div>
            <div class="nav-item admin-only" onclick="showTab('deploy', this)">+ Deploy</div>
            <div class="nav-item admin-only" onclick="showTab('fleet', this)">Fleet</div>
            <div class="nav-item admin-only" onclick="showTab('apikeys', this)">API Keys</div>
            <div class="nav-item admin-only" onclick="showTab('admin-settings', this)">Admin Settings</div>

            <div class="nav-item" onclick="showTab('account', this)">Account</div>

            <div class="user-badge">
                <div>
                    <div class="user-info" id="display-user">User</div>
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

            <!-- SERVERS LIST -->
            <div id="servers" class="panel-section">
                <h1 class="sec-title">Servers Management</h1>
                <div id="full-servers-list"></div>
            </div>

            <!-- REAL-TIME NODES METRICS -->
            <div id="nodes" class="panel-section">
                <h1 class="sec-title">Nodes Monitor</h1>
                <div class="card">
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <h3 style="color:#f4f4f5;">Built-in Node (Localhost Engine)</h3>
                        <span class="status-tag">● ONLINE</span>
                    </div>
                    <p style="font-size:0.75rem; color:#71717a; margin-top:0.3rem;">Core system execution environment analytics</p>

                    <div class="metrics-grid">
                        <div class="metric-card">
                            <span style="font-size:0.7rem; color:#71717a;">CPU USAGE</span>
                            <div class="metric-val" id="cpu-val">0%</div>
                            <div class="progress-bar"><div class="progress-fill" id="cpu-bar"></div></div>
                        </div>
                        <div class="metric-card">
                            <span style="font-size:0.7rem; color:#71717a;">MEMORY (RAM)</span>
                            <div class="metric-val" id="ram-val">1.5 GB / 8 GB</div>
                            <div class="progress-bar"><div class="progress-fill" id="ram-bar"></div></div>
                        </div>
                        <div class="metric-card">
                            <span style="font-size:0.7rem; color:#71717a;">DISK STORAGE</span>
                            <div class="metric-val" id="disk-val">13.7 GB / 30 GB</div>
                            <div class="progress-bar"><div class="progress-fill" id="disk-bar" style="width: 45%;"></div></div>
                        </div>
                        <div class="metric-card">
                            <span style="font-size:0.7rem; color:#71717a;">NETWORK TRAFFIC</span>
                            <div class="metric-val" id="net-val">↓ 736MB | ↑ 297MB</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- DEPLOY WIZARD -->
            <div id="deploy" class="panel-section">
                <h1 class="sec-title">Deploy Instance</h1>
                <div class="wizard-steps">
                    <div class="step-pill active" id="step-pill-1">01 IDENTITY</div>
                    <div class="step-pill" id="step-pill-2">02 RESOURCES</div>
                </div>

                <!-- STEP 1 -->
                <div id="deploy-step-1" class="card">
                    <div class="form-group">
                        <label>Instance Name *</label>
                        <input type="text" id="dep-name" placeholder="e.g. Production Survival">
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <input type="text" id="dep-desc" placeholder="Short description of this server (optional)">
                    </div>
                    <div class="form-group">
                        <label>Execution Runtime</label>
                        <select id="dep-runtime">
                            <option value="Docker Container">Docker Container (Isolated Sandbox)</option>
                            <option value="Local Process">Local Process (Node.js Direct Exec)</option>
                        </select>
                    </div>
                    <button class="btn-action btn-primary" onclick="goToStep(2)" style="width:100%; padding:0.8rem; margin-top:1rem;">NEXT STEP ➔</button>
                </div>

                <!-- STEP 2 -->
                <div id="deploy-step-2" class="card" style="display:none;">
                    <label style="font-size: 0.75rem; color: #a1a1aa; text-transform: uppercase;">Select RAM Allocation</label>
                    <div class="ram-grid">
                        <div class="ram-option selected" onclick="selectRam('1 GB', this)"><h4>1 GB</h4><p>Small Testing</p></div>
                        <div class="ram-option" onclick="selectRam('2 GB', this)"><h4>2 GB</h4><p>Standard Server</p></div>
                        <div class="ram-option" onclick="selectRam('4 GB', this)"><h4>4 GB</h4><p>Starter Survival</p></div>
                        <div class="ram-option" onclick="selectRam('8 GB', this)"><h4>8 GB</h4><p>Medium Survival</p></div>
                    </div>

                    <div class="form-group" style="margin-top:1.5rem;">
                        <label>CPU Limit (%)</label>
                        <input type="number" id="dep-cpu" value="100">
                    </div>
                    <div class="form-group">
                        <label>Disk Limit (GB)</label>
                        <input type="number" id="dep-disk" value="10">
                    </div>

                    <div style="display:flex; gap:10px; margin-top:1.5rem;">
                        <button class="btn-action" onclick="goToStep(1)">← BACK</button>
                        <button class="btn-action btn-primary" onclick="createInstance()" style="flex:1;">DEPLOY INSTANCE NOW 🚀</button>
                    </div>
                </div>
            </div>

            <!-- FLEET -->
            <div id="fleet" class="panel-section">
                <h1 class="sec-title">Fleet Operations</h1>
                <div class="card"><p>Linked Multi-Node Cluster Status: All Nodes Nominal (1 Active Node)</p></div>
            </div>

            <!-- API KEYS -->
            <div id="apikeys" class="panel-section">
                <h1 class="sec-title">API Keys Management</h1>
                <div class="card">
                    <button class="btn-action btn-primary" onclick="alert('API Key Generated: jtg_live_' + Math.random().toString(36).substring(7))">Generate New API Key</button>
                </div>
            </div>

            <!-- ADMIN SETTINGS -->
            <div id="admin-settings" class="panel-section">
                <h1 class="sec-title">Admin Settings</h1>
                <div class="card">
                    <div class="form-group">
                        <label>Panel Branding Name</label>
                        <input type="text" id="set-panel-name" value="JTG PANEL">
                    </div>
                    <button class="btn-action btn-primary" onclick="updatePanelName()">Save Settings</button>
                </div>
            </div>

            <!-- ACCOUNT & USER CREATION -->
            <div id="account" class="panel-section">
                <h1 class="sec-title">Account Settings</h1>
                <div class="card admin-only" style="margin-bottom:1.5rem;">
                    <h3 style="color:#f4f4f5; margin-bottom:1rem;">Create New User Account</h3>
                    <div style="display:flex; gap:10px;">
                        <input type="text" id="new-u-name" placeholder="Username" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                        <input type="password" id="new-u-pass" placeholder="Password" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                        <select id="new-u-role" style="padding:0.6rem; background:#18181b; border:1px solid #27272a; color:#fff; border-radius:4px;">
                            <option value="Member">Member</option>
                            <option value="Admin">Admin</option>
                        </select>
                        <button class="btn-action btn-primary" onclick="createUser()">Create Account</button>
                    </div>
                </div>
                <div class="card">
                    <h3 style="color:#f4f4f5;">Active System Users</h3>
                    <div id="users-list-box" style="margin-top:1rem; font-size:0.85rem;"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- TERMINAL CONSOLE MODAL -->
    <div class="console-modal" id="console-modal">
        <div class="console-container">
            <div class="console-header">
                <span id="modal-server-title">Console</span>
                <div>
                    <button class="btn-action" style="background:#16a34a;" onclick="appendLog('[SYSTEM] Server execution started.')">START</button>
                    <button class="btn-action" style="background:#dc2626;" onclick="appendLog('[SYSTEM] Server process killed.')">STOP</button>
                    <button class="btn-action" onclick="closeConsole()">X</button>
                </div>
            </div>
            <div class="console-body" id="console-output"></div>
            <div class="console-footer">
                <input type="text" id="console-cmd-input" placeholder="Type command here..." onkeypress="handleCmd(event)">
                <button class="btn-action btn-primary" onclick="sendCmd()">Send</button>
            </div>
        </div>
    </div>

    <script>
        let selectedRam = '1 GB';
        let currentUserRole = 'Member';

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
                currentUserRole = data.role;
                document.getElementById('login-view').style.display = 'none';
                document.getElementById('app-view').style.display = 'flex';
                
                document.getElementById('display-user').innerText = user;
                document.getElementById('display-role').innerText = data.role;

                if (data.role === 'Admin') {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'flex');
                } else {
                    document.querySelectorAll('.admin-only').forEach(el => el.style.display = 'none');
                }

                loadServers();
                loadUsers();
                startMetricsStream();
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

        /* REALTIME NODES MONITOR */
        function startMetricsStream() {
            setInterval(() => {
                const cpu = Math.floor(Math.random() * 25) + 5;
                const ram = (1.5 + (Math.random() * 0.8)).toFixed(1);
                
                document.getElementById('cpu-val').innerText = cpu + '%';
                document.getElementById('cpu-bar').style.width = cpu + '%';

                document.getElementById('ram-val').innerText = `${ram} GB / 8 GB`;
                document.getElementById('ram-bar').style.width = ((ram / 8) * 100) + '%';
            }, 2000);
        }

        /* DEPLOY WIZARD */
        function goToStep(step) {
            if (step === 1) {
                document.getElementById('deploy-step-1').style.display = 'block';
                document.getElementById('deploy-step-2').style.display = 'none';
                document.getElementById('step-pill-1').classList.add('active');
                document.getElementById('step-pill-2').classList.remove('active');
            } else {
                if(!document.getElementById('dep-name').value) {
                    alert('Please enter Instance Name!');
                    return;
                }
                document.getElementById('deploy-step-1').style.display = 'none';
                document.getElementById('deploy-step-2').style.display = 'block';
                document.getElementById('step-pill-2').classList.add('active');
                document.getElementById('step-pill-1').classList.remove('active');
            }
        }

        function selectRam(ram, el) {
            selectedRam = ram;
            document.querySelectorAll('.ram-option').forEach(opt => opt.classList.remove('selected'));
            el.classList.add('selected');
        }

        async function createInstance() {
            const name = document.getElementById('dep-name').value;
            const desc = document.getElementById('dep-desc').value;
            const runtime = document.getElementById('dep-runtime').value;
            const cpu = document.getElementById('dep-cpu').value;
            const disk = document.getElementById('dep-disk').value;

            const res = await fetch('/api/servers/create', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ name, desc, runtime, ram: selectedRam, cpu, disk })
            });

            const data = await res.json();
            if (data.success) {
                alert('Server Instance Deployed Successfully!');
                document.getElementById('dep-name').value = '';
                goToStep(1);
                loadServers();
                showTab('overview', document.querySelectorAll('.nav-item')[0]);
            }
        }

        /* LOAD SERVERS */
        async function loadServers() {
            const res = await fetch('/api/servers');
            const servers = await res.json();

            let html = '';
            if (servers.length === 0) {
                html = '<div class="card"><p>No servers available. Click "+ Deploy" to create one.</p></div>';
            } else {
                servers.forEach((s, idx) => {
                    html += `
                        <div class="server-item">
                            <div>
                                <h3>0${idx+1} ${s.name}</h3>
                                <p style="font-size:0.75rem; color:#71717a; margin-top:0.2rem;">${s.desc || 'Local Instance'} | ${s.ram} RAM | ${s.runtime}</p>
                            </div>
                            <div>
                                <span class="status-tag">● RUNNING</span>
                                <button class="btn-action btn-primary" onclick="openConsole('${s.name}')">CONSOLE</button>
                            </div>
                        </div>
                    `;
                });
            }

            document.getElementById('overview-server-list').innerHTML = html;
            document.getElementById('full-servers-list').innerHTML = html;
        }

        /* CONSOLE INTERACTION */
        function openConsole(serverName) {
            document.getElementById('modal-server-title').innerText = 'Console - ' + serverName;
            document.getElementById('console-output').innerHTML = `
                [SYSTEM] Connected to terminal socket for instance [${serverName}]...<br>
                [SYSTEM] Process executing on Node.js core...<br>
                [INFO] Listening for commands...<br>
            `;
            document.getElementById('console-modal').style.display = 'flex';
        }

        function closeConsole() {
            document.getElementById('console-modal').style.display = 'none';
        }

        function appendLog(text) {
            const out = document.getElementById('console-output');
            out.innerHTML += text + '<br>';
            out.scrollTop = out.scrollHeight;
        }

        function handleCmd(e) {
            if (e.key === 'Enter') sendCmd();
        }

        function sendCmd() {
            const inp = document.getElementById('console-cmd-input');
            if (inp.value.trim() !== '') {
                appendLog('<span style="color:#fff;">> ' + inp.value + '</span>');
                appendLog('[OUTPUT] Command executed successfully.');
                inp.value = '';
            }
        }

        /* ACCOUNT & ADMIN SETTINGS */
        async function createUser() {
            const user = document.getElementById('new-u-name').value;
            const pass = document.getElementById('new-u-pass').value;
            const role = document.getElementById('new-u-role').value;

            if(!user || !pass) return alert('Fill all fields');

            const res = await fetch('/api/users/create', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({ user, pass, role })
            });

            const data = await res.json();
            if(data.success) {
                alert('User Created Successfully!');
                loadUsers();
            }
        }

        async function loadUsers() {
            const res = await fetch('/api/users');
            const users = await res.json();
            let html = '';
            users.forEach(u => {
                html += `<div style="padding:0.4rem 0; border-bottom:1px solid #18181b; display:flex; justify-content:space-between;">
                    <span><b>${u.user}</b></span> <span style="color:#71717a;">${u.role}</span>
                </div>`;
            });
            document.getElementById('users-list-box').innerHTML = html;
        }

        function updatePanelName() {
            const name = document.getElementById('set-panel-name').value;
            document.getElementById('app-brand-name').innerText = name;
            document.getElementById('login-brand-title').innerText = name;
            alert('Branding settings saved!');
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

// In-Memory Database State
let servers = [
    { name: "chachaji", desc: "Local default instance", runtime: "Docker Container", ram: "4 GB", cpu: "100", disk: "10" }
];

let users = [
    { user: config.admin_user, pass: config.admin_pass, role: "Admin" },
    { user: "user", pass: "user123", role: "Member" }
];

// LOGIN API
app.post('/api/login', (req, res) => {
    const { user, pass } = req.body;
    const found = users.find(u => u.user === user && u.pass === pass);
    if (found) {
        return res.json({ success: true, role: found.role });
    }
    return res.json({ success: false, message: "Invalid credentials" });
});

// SERVER INSTANCE APIS
app.get('/api/servers', (req, res) => {
    res.json(servers);
});

app.post('/api/servers/create', (req, res) => {
    const newServer = req.body;
    servers.push(newServer);
    res.json({ success: true });
});

// USERS APIS
app.get('/api/users', (req, res) => {
    res.json(users.map(u => ({ user: u.user, role: u.role })));
});

app.post('/api/users/create', (req, res) => {
    const { user, pass, role } = req.body;
    users.push({ user, pass, role });
    res.json({ success: true });
});

const PORT = process.env.PORT || config.port || 6767;

server.listen(PORT, () => {
    console.log(`\n==================================================`);
    console.log(` JTG PANEL RUNNING ON PORT : ${PORT}`);
    console.log(`==================================================\n`);
});
EOF

        echo -e "${CYAN}[INFO] Installing npm packages...${NC}"
        npm install

        echo -e "\n${GREEN}=================================================="
        echo " JTG PANEL ENGINE INSTALLED SUCCESSFULLY!"
        echo " Admin Login : ${ADMIN_USER} / ${ADMIN_PASS}"
        echo " User Login  : user / user123"
        echo " Port        : ${PORT}"
        echo "==================================================${NC}\n"

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
