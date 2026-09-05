const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
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

// Database Mocking (Servers & Nodes)
let servers = [
    { id: "srv-chachaji", name: "chachaji", port: 25563, status: "OFFLINE", cpu: "999%", ram: "99999 GB", disk: "99999 GB", version: "1.21.11" },
    { id: "srv-ff", name: "ff", port: 25565, status: "OFFLINE", cpu: "999%", ram: "99999 GB", disk: "99999 GB", version: "1.21.11" }
];

let nodes = [
    { name: "Built-in Node (Local)", host: "localhost — Core System Node", status: "ONLINE", uptime: "12h 50m", cpu: "0%", ram: "19%", disk: "47%" },
    { name: "Local Node", host: "localhost — Core System Node", status: "ONLINE", uptime: "12h 50m", cpu: "0%", ram: "19%", disk: "47%" }
];

// Authentication API
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === config.admin_user && password === config.admin_pass) {
        res.json({ success: true, token: "cjh-auth-key-valid", user: username });
    } else {
        res.status(401).json({ success: false, message: "Invalid Admin Credentials" });
    }
});

// Data Routes
app.get('/api/servers', (req, res) => res.json(servers));
app.get('/api/nodes', (req, res) => res.json(nodes));

// Web Socket Console Stream
io.on('connection', (socket) => {
    socket.emit('console-log', '[SYSTEM] Sandbox mode initialized. Terminal connection secured.');

    socket.on('start-server', (serverId) => {
        const srv = servers.find(s => s.id === serverId);
        if (srv) {
            srv.status = "ONLINE";
            socket.emit('console-log', `[SYSTEM] Booting server instance '${srv.name}' on port ${srv.port}...`);
            socket.emit('console-log', `[SERVER] Loading server properties & core binaries...`);
            socket.emit('console-log', `[SERVER] Done! Server live on address: 0.0.0.0:${srv.port}`);
            io.emit('server-status-updated', srv);
        }
    });

    socket.on('stop-server', (serverId) => {
        const srv = servers.find(s => s.id === serverId);
        if (srv) {
            srv.status = "OFFLINE";
            socket.emit('console-log', `[SYSTEM] Stopping server instance '${srv.name}'...`);
            socket.emit('console-log', `[SERVER] Saving world chunks and player data...`);
            socket.emit('console-log', `[SERVER] Process terminated successfully.`);
            io.emit('server-status-updated', srv);
        }
    });

    socket.on('command', (data) => {
        socket.emit('console-log', `> ${data.command}`);
        socket.emit('console-log', `[EXEC] Executed command: ${data.command}`);
    });
});

server.listen(config.port, '0.0.0.0', () => {
    console.log(`CJH Panel running on http://0.0.0.0:${config.port}`);
});
