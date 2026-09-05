#!/bin/bash
# =========================================================
# CJH PANEL v6.0 - ENTERPRISE MINECRAFT ENGINE
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
echo "║             CJH PANEL v6.0                   ║"
echo "║     Enterprise Minecraft Engine              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

OPTION=$1

if [ -z "$OPTION" ]; then
    echo -e "${YELLOW}Choose an option:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Install / Update CJH Panel"
    echo -e "  ${GREEN}[2]${NC} Restart CJH Service"
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
  "version": "6.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

        mkdir -p public
        mkdir -p mc_servers

        # ---------------------------------------------------------
        # FRONTEND (public/index.html)
        # ---------------------------------------------------------
        cat <<'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CJH PANEL - Enterprise Hosting</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://unpkg.com/lucide@latest"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    body { font-family: 'Inter', sans-serif; }
    .font-mono { font-family: 'JetBrains Mono', monospace; }
  </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col md:flex-row">

  <!-- SIDEBAR -->
  <aside class="w-full md:w-64 bg-slate-900 border-r border-slate-800 flex flex-col justify-between shrink-0">
    <div>
      <div class="p-5 border-b border-slate-800 flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <div class="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 font-bold">
            <i data-lucide="box" class="w-6 h-6"></i>
          </div>
          <div>
            <h1 class="font-bold text-base text-white tracking-wide">CJH PANEL</h1>
            <span class="text-[10px] text-emerald-400 font-semibold tracking-wider uppercase">Enterprise v6.0</span>
          </div>
        </div>
      </div>

      <nav class="p-3 space-y-1">
        <button onclick="switchTab('dashboard')" id="nav-dashboard" class="nav-btn w-full flex items-center space-x-3 px-3.5 py-2.5 bg-emerald-500/10 text-emerald-400 rounded-xl font-medium border border-emerald-500/20 text-sm transition">
          <i data-lucide="terminal" class="w-4 h-4"></i>
          <span>Console & Stats</span>
        </button>
        
        <button onclick="switchTab('installer')" id="nav-installer" class="nav-btn w-full flex items-center space-x-3 px-3.5 py-2.5 text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 rounded-xl font-medium text-sm transition">
          <i data-lucide="download-cloud" class="w-4 h-4"></i>
          <span>Version Installer</span>
        </button>

        <button onclick="switchTab('files')" id="nav-files" class="nav-btn w-full flex items-center space-x-3 px-3.5 py-2.5 text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 rounded-xl font-medium text-sm transition">
          <i data-lucide="folder" class="w-4 h-4"></i>
          <span>File Manager</span>
        </button>
      </nav>
    </div>

    <div class="p-3 border-t border-slate-800">
      <div class="flex items-center justify-between p-2.5 rounded-xl bg-slate-800/40 border border-slate-700/40">
        <div class="flex items-center space-x-3">
          <div class="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center font-bold text-xs text-white">A</div>
          <div>
            <p class="text-xs font-semibold text-white">Administrator</p>
            <p class="text-[10px] text-slate-400">admin@cjhpanel.com</p>
          </div>
        </div>
      </div>
    </div>
  </aside>

  <!-- MAIN CONTENT -->
  <main class="flex-1 flex flex-col min-w-0 overflow-y-auto">
    <header class="h-16 bg-slate-900/60 border-b border-slate-800 backdrop-blur-md flex items-center justify-between px-6 sticky top-0 z-20">
      <div class="flex items-center space-x-3">
        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse mr-2"></span>
          ONLINE
        </span>
        <h2 class="text-sm font-semibold text-slate-200">Survival Server #1</h2>
      </div>

      <div class="flex items-center space-x-2">
        <button onclick="sendPower('start')" class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1 transition">
          <i data-lucide="play" class="w-3.5 h-3.5"></i>
          <span>Start</span>
        </button>
        <button onclick="sendPower('restart')" class="px-3 py-1.5 bg-amber-600 hover:bg-amber-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1 transition">
          <i data-lucide="rotate-cw" class="w-3.5 h-3.5"></i>
          <span>Restart</span>
        </button>
        <button onclick="sendPower('stop')" class="px-3 py-1.5 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1 transition">
          <i data-lucide="square" class="w-3.5 h-3.5"></i>
          <span>Stop</span>
        </button>
      </div>
    </header>

    <div class="p-6">
      <!-- DASHBOARD TAB -->
      <div id="tab-dashboard" class="tab-content space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <span class="text-xs font-semibold uppercase text-slate-400">CPU Load</span>
            <div class="text-2xl font-bold text-white">0.6%</div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-emerald-500 h-full" style="width: 15%"></div>
            </div>
          </div>
          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <span class="text-xs font-semibold uppercase text-slate-400">RAM Usage</span>
            <div class="text-2xl font-bold text-white">1.40 GB / 8 GB</div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-blue-500 h-full" style="width: 18%"></div>
            </div>
          </div>
          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <span class="text-xs font-semibold uppercase text-slate-400">Disk Storage</span>
            <div class="text-2xl font-bold text-white">12.85 GB / 30 GB</div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-purple-500 h-full" style="width: 42%"></div>
            </div>
          </div>
        </div>

        <div class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden flex flex-col h-[400px]">
          <div class="bg-slate-950 p-4 font-mono text-xs flex-1 overflow-y-auto space-y-1.5" id="console-logs">
            <p class="text-slate-500">[SYSTEM]: CJH Engine initialized successfully.</p>
          </div>
          <div class="p-3 bg-slate-900 border-t border-slate-800">
            <form onsubmit="handleCmd(event)" class="flex space-x-2">
              <input id="cmd-input" type="text" placeholder="Enter server command..." class="flex-1 bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none">
              <button type="submit" class="bg-emerald-600 text-white px-3 py-1.5 rounded-lg text-xs font-semibold">Send</button>
            </form>
          </div>
        </div>
      </div>

      <!-- INSTALLER TAB -->
      <div id="tab-installer" class="tab-content hidden space-y-6">
        <h3 class="text-lg font-bold text-white">Version Selector</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-4">
            <h4 class="font-bold text-white">PaperMC</h4>
            <select id="paper-ver" class="w-full bg-slate-950 border border-slate-800 rounded-xl p-2 text-xs text-white">
              <option value="1.20.4">Paper 1.20.4</option>
              <option value="1.20.2">Paper 1.20.2</option>
            </select>
            <button onclick="installSoftware('PaperMC', 'paper-ver')" class="w-full py-2 bg-emerald-600 text-white rounded-xl text-xs font-semibold">Install Paper</button>
          </div>
          <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-4">
            <h4 class="font-bold text-white">Purpur</h4>
            <select id="purpur-ver" class="w-full bg-slate-950 border border-slate-800 rounded-xl p-2 text-xs text-white">
              <option value="1.20.4">Purpur 1.20.4</option>
            </select>
            <button onclick="installSoftware('Purpur', 'purpur-ver')" class="w-full py-2 bg-purple-600 text-white rounded-xl text-xs font-semibold">Install Purpur</button>
          </div>
        </div>
      </div>

      <!-- FILE MANAGER TAB -->
      <div id="tab-files" class="tab-content hidden space-y-4">
        <div class="bg-slate-900 p-4 rounded-2xl border border-slate-800 flex justify-between items-center">
          <h3 class="font-bold text-sm text-white">File Directory</h3>
          <button onclick="loadFiles()" class="px-3 py-1.5 bg-slate-800 text-xs font-semibold rounded-lg">Refresh List</button>
        </div>
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-4">
          <tbody id="files-tbody" class="text-xs text-slate-300">
            <p class="text-slate-500">Loading files...</p>
          </tbody>
        </div>
      </div>
    </div>
  </main>

  <script>
    lucide.createIcons();

    function switchTab(id) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
      document.getElementById('tab-' + id).classList.remove('hidden');
      if (id === 'files') loadFiles();
    }

    function sendPower(action) {
      const logs = document.getElementById('console-logs');
      logs.innerHTML += `<p class="text-emerald-400">[POWER]: Server action -> ${action.toUpperCase()}</p>`;
      logs.scrollTop = logs.scrollHeight;
    }

    function handleCmd(e) {
      e.preventDefault();
      const input = document.getElementById('cmd-input');
      const logs = document.getElementById('console-logs');
      if(!input.value) return;
      logs.innerHTML += `<p class="text-white">&gt; ${input.value}</p>`;
      input.value = '';
      logs.scrollTop = logs.scrollHeight;
    }

    function installSoftware(name, id) {
      const ver = document.getElementById(id).value;
      switchTab('dashboard');
      const logs = document.getElementById('console-logs');
      logs.innerHTML += `<p class="text-blue-400">[INSTALLER]: Installing ${name} v${ver}...</p>`;
      logs.scrollTop = logs.scrollHeight;
    }

    async function loadFiles() {
      const res = await fetch('/api/files');
      const files = await res.json();
      const tbody = document.getElementById('files-tbody');
      tbody.innerHTML = files.map(f => `<div class="p-2 border-b border-slate-800 flex justify-between"><span>${f.name}</span><span class="text-slate-500">${f.size}</span></div>`).join('') || '<p>No files.</p>';
    }
  </script>
</body>
</html>
EOF

        # ---------------------------------------------------------
        # BACKEND (server.js)
        # ---------------------------------------------------------
        cat <<'EOF' > server.js
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const CONFIG_FILE = path.join(__dirname, 'config.json');

app.get('/api/files', (req, res) => {
    const srvDir = path.join(__dirname, 'mc_servers');
    if (!fs.existsSync(srvDir)) fs.mkdirSync(srvDir, { recursive: true });

    const files = fs.readdirSync(srvDir).map(file => {
        const stats = fs.statSync(path.join(srvDir, file));
        return { name: file, size: (stats.size / 1024).toFixed(1) + ' KB' };
    });
    res.json(files);
});

const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
app.listen(config.port, () => {
    console.log(`[CJH PANEL] Engine running on port ${config.port}`);
});
EOF

        echo -e "${GREEN}Installing dependencies...${NC}"
        npm install

        echo -e "${GREEN}Configuring Service...${NC}"
        if command -v systemctl &> /dev/null; then
            cat <<EOF | sudo tee /etc/systemd/system/cjh-panel.service > /dev/null
[Unit]
Description=CJH Panel Minecraft Engine
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(which node) $(pwd)/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF
            sudo systemctl daemon-reload
            sudo systemctl enable cjh-panel
            sudo systemctl restart cjh-panel
            echo -e "${GREEN}Service 'cjh-panel' started successfully!${NC}"
        else
            node server.js &
        fi

        echo -e "\n${CYAN}========================================================${NC}"
        echo -e "${GREEN}CJH PANEL v6.0 INSTALLATION COMPLETE!${NC}"
        echo -e "Panel Address: ${YELLOW}http://localhost:${PORT}${NC}"
        echo -e "${CYAN}========================================================${NC}"
        ;;

    2)
        if command -v systemctl &> /dev/null; then
            sudo systemctl restart cjh-panel
            echo -e "${GREEN}CJH Panel Service restarted.${NC}"
        fi
        ;;

    3)
        exit 0
        ;;
esac
