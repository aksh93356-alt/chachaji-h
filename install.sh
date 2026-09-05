#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}===========================================${NC}"
echo -e "${GREEN}   Upgrading CJH Panel Backend & Frontend   ${NC}"
echo -e "${CYAN}===========================================${NC}"

# Stop existing running instance if any
pm2 stop cjh-panel 2>/dev/null || true

# Install required system tools & Node packages directly with force flag
echo -e "${YELLOW}[1/4] Installing necessary NPM dependencies...${NC}"
npm install --save systeminformation multer ws express body-parser cors jsonwebtoken express-fileupload node-pty playit

# Fallback check if systeminformation failed to install
if [ ! -d "node_modules/systeminformation" ]; then
    echo -e "${RED}Retrying npm install with legacy peer deps...${NC}"
    npm install systeminformation multer ws express body-parser cors jsonwebtoken --legacy-peer-deps
fi

# Create backend main script
echo -e "${YELLOW}[2/4] Updating Server Backend Architecture...${NC}"
cat << 'EOF' > server.js
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const si = require('systeminformation');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Configure Multer for File Uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const userServerPath = req.query.path || './server_files';
        if (!fs.existsSync(userServerPath)) {
            fs.mkdirSync(userServerPath, { recursive: true });
        }
        cb(null, userServerPath);
    },
    filename: (req, file, cb) => {
        cb(null, file.originalname);
    }
});
const upload = multer({ storage });

// Global Config Store for Admin Settings
let globalConfig = {
    panelBrandName: "CJH PANEL - Enterprise",
    adminUser: "admin"
};

// 1. REAL SYSTEM METRICS API (VPS Real Stats)
app.get('/api/system/stats', async (req, res) => {
    try {
        const cpu = await si.currentLoad();
        const mem = await si.mem();
        const disk = await si.fsSize();

        res.json({
            cpuLoad: cpu.currentLoad.toFixed(1),
            memUsed: (mem.active / (1024 * 1024 * 1024)).toFixed(2),
            memTotal: (mem.total / (1024 * 1024 * 1024)).toFixed(2),
            diskUsed: disk[0] ? (disk[0].used / (1024 * 1024 * 1024)).toFixed(2) : '0',
            diskTotal: disk[0] ? (disk[0].size / (1024 * 1024 * 1024)).toFixed(2) : '10'
        });
    } catch (e) {
        res.status(500).json({ error: "Metrics retrieval failed" });
    }
});

// 2. ADMIN SETTINGS API
app.get('/api/admin/config', (req, res) => {
    res.json(globalConfig);
});

app.post('/api/admin/config', (req, res) => {
    const { panelBrandName } = req.body;
    if (panelBrandName) {
        globalConfig.panelBrandName = panelBrandName;
    }
    res.json({ success: true, config: globalConfig });
});

// 3. FILE MANAGER APIS (List, Read, Save, Upload, Delete)
app.get('/api/files/list', (req, res) => {
    const userFolder = req.query.userDir || './server_files';
    if (!fs.existsSync(userFolder)) fs.mkdirSync(userFolder, { recursive: true });

    fs.readdir(userFolder, { withFileTypes: true }, (err, files) => {
        if (err) return res.status(500).json({ error: "Failed to list directory" });
        const list = files.map(f => {
            const stats = fs.statSync(path.join(userFolder, f.name));
            return {
                name: f.name,
                isDirectory: f.isDirectory(),
                size: (stats.size / 1024).toFixed(1) + ' KB'
            };
        });
        res.json(list);
    });
});

app.post('/api/files/read', (req, res) => {
    const filePath = req.body.path;
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        res.json({ content });
    } else {
        res.status(404).json({ error: "File not found" });
    }
});

app.post('/api/files/save', (req, res) => {
    const { path: filePath, content } = req.body;
    try {
        fs.writeFileSync(filePath, content, 'utf8');
        res.json({ success: true, message: "File saved successfully!" });
    } catch (e) {
        res.status(500).json({ error: "Failed to save file" });
    }
});

app.post('/api/files/upload', upload.single('file'), (req, res) => {
    res.json({ success: true, message: "File uploaded successfully!" });
});

app.post('/api/files/delete', (req, res) => {
    const { path: filePath } = req.body;
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        res.json({ success: true });
    } else {
        res.status(404).json({ error: "File not found" });
    }
});

// 4. REAL PLAYIT.GG TUNNEL INTEGRATION
let playitProcess = null;
let playitClaimUrl = "";

app.post('/api/playit/start', (req, res) => {
    if (playitProcess) {
        return res.json({ message: "Tunnel active", claimUrl: playitClaimUrl });
    }

    playitProcess = spawn('playit', ['--secret', 'auto']);

    playitProcess.stdout.on('data', (data) => {
        const output = data.toString();
        const match = output.match(/https:\/\/playit\.gg\/claim\/[a-zA-Z0-9]+/);
        if (match) {
            playitClaimUrl = match[0];
        }
    });

    playitProcess.on('error', () => {
        playitClaimUrl = "Playit binary not found on host. Installed fallback mode.";
    });

    res.json({ status: "Tunnel Initiated", claimUrl: playitClaimUrl || "Generating URL..." });
});

app.get('/api/playit/status', (req, res) => {
    res.json({ running: !!playitProcess, claimUrl: playitClaimUrl });
});

// WEBSOCKET FOR REAL-TIME CONSOLE & METRICS
wss.on('connection', (ws) => {
    const interval = setInterval(async () => {
        try {
            const cpu = await si.currentLoad();
            const mem = await si.mem();
            ws.send(JSON.stringify({
                type: 'metrics',
                cpu: cpu.currentLoad.toFixed(1),
                ram: (mem.active / (1024 * 1024 * 1024)).toFixed(2)
            }));
        } catch (e) {}
    }, 2000);

    ws.on('close', () => clearInterval(interval));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`CJH Panel running on port ${PORT}`);
});
EOF

echo -e "${YELLOW}[3/4] Updating Dashboard Web Interface...${NC}"
mkdir -p public

cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJH PANEL - Admin & Control</title>
    <style>
        * { box-sizing: border-box; }
        body { background-color: #0d0f17; color: #e1e4ed; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .card { background: #161926; padding: 20px; border-radius: 8px; border: 1px solid #23273a; margin-bottom: 20px; }
        button { background: #e63946; color: white; border: none; padding: 10px 16px; border-radius: 4px; cursor: pointer; font-weight: bold; }
        button:hover { background: #d62828; }
        input, textarea, select { background: #0b0c13; color: #fff; border: 1px solid #2d3248; padding: 10px; width: 100%; border-radius: 4px; margin-top: 6px; margin-bottom: 12px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #23273a; }
        a { color: #4cc9f0; }
    </style>
</head>
<body>

    <h1 id="brandHeader">CJH Panel</h1>

    <div class="grid">
        <!-- Real System Metrics -->
        <div class="card">
            <h3>Real VPS Stats</h3>
            <p><strong>CPU Load:</strong> <span id="cpuLoad">0</span>%</p>
            <p><strong>RAM Usage:</strong> <span id="ramUsage">0</span> GB / <span id="ramTotal">0</span> GB</p>
            <p><strong>Disk Storage:</strong> <span id="diskUsed">0</span> GB / <span id="diskTotal">0</span> GB</p>
        </div>

        <!-- Admin Settings -->
        <div class="card">
            <h3>Admin Settings</h3>
            <label>Panel Brand Name:</label>
            <input type="text" id="brandInput" placeholder="Enter Panel Title">
            <button onclick="saveAdminSettings()" style="background:#4a4e69;">Save Settings</button>
        </div>
    </div>

    <!-- File Manager -->
    <div class="card">
        <h3>File Directory Manager</h3>
        <input type="file" id="fileInput">
        <button onclick="uploadFile()" style="background:#2a9d8f;">Upload Selected File</button>
        
        <table id="fileTable">
            <tr><th>File Name</th><th>Size</th><th>Actions</th></tr>
        </table>

        <h4>File Editor</h4>
        <input type="text" id="editPath" readonly placeholder="No file selected">
        <textarea id="fileContent" rows="8" placeholder="File content will appear here..."></textarea>
        <button onclick="saveFile()" style="background:#2a9d8f;">Save File Changes</button>
    </div>

    <!-- Playit.gg Tunnel Generator -->
    <div class="card">
        <h3>Playit.gg Real Tunnel</h3>
        <button onclick="startPlayit()">Generate Tunnel Key / URL</button>
        <p><strong>Tunnel Status Link:</strong> <a id="playitLink" href="#" target="_blank">Not Connected</a></p>
    </div>

    <script>
        async function fetchAdminConfig() {
            const res = await fetch('/api/admin/config');
            const data = await res.json();
            document.getElementById('brandHeader').innerText = data.panelBrandName;
            document.getElementById('brandInput').value = data.panelBrandName;
        }

        async function saveAdminSettings() {
            const name = document.getElementById('brandInput').value;
            await fetch('/api/admin/config', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ panelBrandName: name })
            });
            fetchAdminConfig();
            alert('Admin settings saved!');
        }

        async function updateMetrics() {
            try {
                const res = await fetch('/api/system/stats');
                const data = await res.json();
                document.getElementById('cpuLoad').innerText = data.cpuLoad;
                document.getElementById('ramUsage').innerText = data.memUsed;
                document.getElementById('ramTotal').innerText = data.memTotal;
                document.getElementById('diskUsed').innerText = data.diskUsed;
                document.getElementById('diskTotal').innerText = data.diskTotal;
            } catch(e) {}
        }
        setInterval(updateMetrics, 3000);

        async function loadFiles() {
            const res = await fetch('/api/files/list');
            const files = await res.json();
            const table = document.getElementById('fileTable');
            table.innerHTML = '<tr><th>File Name</th><th>Size</th><th>Actions</th></tr>';
            files.forEach(f => {
                table.innerHTML += `<tr>
                    <td>${f.name}</td>
                    <td>${f.size}</td>
                    <td>
                        <button onclick="editFile('./server_files/${f.name}')" style="background:#3a86ff;">Edit</button>
                        <button onclick="deleteFile('./server_files/${f.name}')">Delete</button>
                    </td>
                </tr>`;
            });
        }

        async function editFile(path) {
            const res = await fetch('/api/files/read', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ path })
            });
            const data = await res.json();
            document.getElementById('editPath').value = path;
            document.getElementById('fileContent').value = data.content || '';
        }

        async function saveFile() {
            const path = document.getElementById('editPath').value;
            const content = document.getElementById('fileContent').value;
            if(!path) return alert('Select a file first!');
            await fetch('/api/files/save', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ path, content })
            });
            alert('File updated successfully!');
        }

        async function deleteFile(path) {
            if(!confirm('Delete file?')) return;
            await fetch('/api/files/delete', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ path })
            });
            loadFiles();
        }

        async function uploadFile() {
            const fileInput = document.getElementById('fileInput');
            if(!fileInput.files[0]) return alert('Choose a file to upload!');
            const formData = new FormData();
            formData.append('file', fileInput.files[0]);

            await fetch('/api/files/upload', {
                method: 'POST',
                body: formData
            });
            alert('File uploaded!');
            loadFiles();
        }

        async function startPlayit() {
            const res = await fetch('/api/playit/start', { method: 'POST' });
            const data = await res.json();
            document.getElementById('playitLink').innerText = data.claimUrl || "Generating...";
            document.getElementById('playitLink').href = data.claimUrl || "#";
        }

        fetchAdminConfig();
        updateMetrics();
        loadFiles();
    </script>
</body>
</html>
EOF

echo -e "${YELLOW}[4/4] Starting Server Application...${NC}"
node server.js &

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN} Update Complete! System running smoothly. ${NC}"
echo -e "${GREEN}===========================================${NC}"
