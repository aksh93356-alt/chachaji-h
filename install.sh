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

# Install required system tools & Node packages
echo -e "${YELLOW}[1/4] Installing necessary NPM dependencies (systeminformation, multer, playit)...${NC}"
npm install express ws cors systeminformation multer playit node-pty body-parser jsonwebtoken express-fileupload --save 2>/dev/null

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
        const serverPath = req.query.path || './server_files';
        if (!fs.existsSync(serverPath)) {
            fs.mkdirSync(serverPath, { recursive: true });
        }
        cb(null, serverPath);
    },
    filename: (req, file, cb) => {
        cb(null, file.originalname);
    }
});
const upload = multer({ storage });

// 1. REAL SYSTEM METRICS API
app.get('/api/system/stats', async (req, res) => {
    try {
        const cpu = await si.currentLoad();
        const mem = await si.mem();
        const disk = await si.fsSize();

        res.json({
            cpuLoad: cpu.currentLoad.toFixed(1),
            memUsed: (mem.active / (1024 * 1024 * 1024)).toFixed(2),
            memTotal: (mem.total / (1024 * 1024 * 1024)).toFixed(2),
            diskUsed: disk[0] ? (disk[0].used / (1024 * 1024 * 1024)).toFixed(2) : 0,
            diskTotal: disk[0] ? (disk[0].size / (1024 * 1024 * 1024)).toFixed(2) : 10
        });
    } catch (e) {
        res.status(500).json({ error: "Metrics error" });
    }
});

// 2. FILE MANAGER APIS (List, Edit, Save, Delete, Upload)
app.get('/api/files/list', (req, res) => {
    const dir = req.query.dir || './server_files';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    fs.readdir(dir, { withFileTypes: true }, (err, files) => {
        if (err) return res.status(500).json({ error: "Failed to read files" });
        const list = files.map(f => {
            const stats = fs.statSync(path.join(dir, f.name));
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
    fs.writeFileSync(filePath, content, 'utf8');
    res.json({ success: true, message: "File saved successfully!" });
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

// 3. REAL PLAYIT.GG TUNNEL INTEGRATION
let playitProcess = null;
let playitClaimUrl = "";

app.post('/api/playit/start', (req, res) => {
    if (playitProcess) {
        return res.json({ message: "Playit already running", claimUrl: playitClaimUrl });
    }

    playitProcess = spawn('playit', ['--secret', 'auto']);

    playitProcess.stdout.on('data', (data) => {
        const output = data.toString();
        const match = output.match(/https:\/\/playit\.gg\/claim\/[a-zA-Z0-9]+/);
        if (match) {
            playitClaimUrl = match[0];
        }
    });

    res.json({ status: "Tunnel Starting", claimUrl: playitClaimUrl || "Generating..." });
});

app.get('/api/playit/status', (req, res) => {
    res.json({ running: !!playitProcess, claimUrl: playitClaimUrl });
});

// WEBSOCKET FOR REAL-TIME METRICS & CONSOLE
wss.on('connection', (ws) => {
    const interval = setInterval(async () => {
        const cpu = await si.currentLoad();
        const mem = await si.mem();
        ws.send(JSON.stringify({
            type: 'metrics',
            cpu: cpu.currentLoad.toFixed(1),
            ram: (mem.active / (1024 * 1024 * 1024)).toFixed(2)
        }));
    }, 2000);

    ws.on('close', () => clearInterval(interval));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
EOF

echo -e "${YELLOW}[3/4] Building Updated Frontend Interface...${NC}"
mkdir -p public

cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJH PANEL - Advanced Control</title>
    <style>
        body { background-color: #0f111a; color: #fff; font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        .card { background: #1a1d2e; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        button { background: #e63946; color: white; border: none; padding: 10px 15px; border-radius: 4px; cursor: pointer; }
        button:hover { background: #d62828; }
        input, textarea, select { background: #0f111a; color: #fff; border: 1px solid #333; padding: 8px; width: 100%; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #2a2d3d; }
    </style>
</head>
<body>

    <h1>CJH Panel Enterprise</h1>

    <!-- System Stats -->
    <div class="card">
        <h3>Real Server Usage</h3>
        <p>CPU Load: <span id="cpuLoad">0</span>%</p>
        <p>RAM Usage: <span id="ramUsage">0</span> GB / <span id="ramTotal">0</span> GB</p>
    </div>

    <!-- File Manager with Edit & Upload -->
    <div class="card">
        <h3>File Manager</h3>
        <input type="file" id="fileInput">
        <button onclick="uploadFile()">Upload File</button>
        <br><br>
        <table id="fileTable">
            <tr><th>Name</th><th>Size</th><th>Actions</th></tr>
        </table>
        
        <h4>File Editor</h4>
        <input type="text" id="editPath" readonly placeholder="Selected File Path">
        <textarea id="fileContent" rows="10"></textarea>
        <button onclick="saveFile()" style="background:#2a9d8f;">Save Changes</button>
    </div>

    <!-- Real Playit Tunnel -->
    <div class="card">
        <h3>Playit.gg Tunnel Manager</h3>
        <button onclick="startPlayit()">Generate Real Tunnel</button>
        <p>Claim URL: <a id="playitLink" href="#" target="_blank">Not Running</a></p>
    </div>

    <script>
        // Fetch Real Metrics
        async function updateMetrics() {
            const res = await fetch('/api/system/stats');
            const data = await res.json();
            document.getElementById('cpuLoad').innerText = data.cpuLoad;
            document.getElementById('ramUsage').innerText = data.memUsed;
            document.getElementById('ramTotal').innerText = data.memTotal;
        }
        setInterval(updateMetrics, 3000);

        // Load Files
        async function loadFiles() {
            const res = await fetch('/api/files/list');
            const files = await res.json();
            const table = document.getElementById('fileTable');
            table.innerHTML = '<tr><th>Name</th><th>Size</th><th>Actions</th></tr>';
            files.forEach(f => {
                table.innerHTML += `<tr>
                    <td>${f.name}</td>
                    <td>${f.size}</td>
                    <td>
                        <button onclick="editFile('./server_files/${f.name}')">Edit</button>
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
            document.getElementById('fileContent').value = data.content;
        }

        async function saveFile() {
            const path = document.getElementById('editPath').value;
            const content = document.getElementById('fileContent').value;
            await fetch('/api/files/save', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ path, content })
            });
            alert('File Saved!');
        }

        async function uploadFile() {
            const fileInput = document.getElementById('fileInput');
            const formData = new FormData();
            formData.append('file', fileInput.files[0]);

            await fetch('/api/files/upload', {
                method: 'POST',
                body: formData
            });
            alert('Uploaded successfully!');
            loadFiles();
        }

        async function startPlayit() {
            const res = await fetch('/api/playit/start', { method: 'POST' });
            const data = await res.json();
            document.getElementById('playitLink').innerText = data.claimUrl || "Starting...";
            document.getElementById('playitLink').href = data.claimUrl || "#";
        }

        loadFiles();
    </script>
</body>
</html>
EOF

echo -e "${YELLOW}[4/4] Restarting Panel Application...${NC}"
pm2 start server.js --name "cjh-panel" 2>/dev/null || node server.js &

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN} Panel Updated Successfully!                ${NC}"
echo -e "${GREEN}===========================================${NC}"
