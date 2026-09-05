<!DOCTYPE html>
<html lang="en" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CJH PANEL - Enterprise Hosting</title>
  <!-- Tailwind CSS CDN -->
  <script src="https://cdn.tailwindcss.com"></script>
  <!-- Lucide Icons -->
  <script src="https://unpkg.com/lucide@latest"></script>
  <!-- Google Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          fontFamily: {
            sans: ['Inter', 'sans-serif'],
            mono: ['JetBrains Mono', 'monospace'],
          }
        }
      }
    }
  </script>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col md:flex-row font-sans">

  <!-- SIDEBAR -->
  <aside class="w-full md:w-64 bg-slate-900 border-r border-slate-800 flex flex-col justify-between shrink-0">
    <div>
      <!-- Brand Logo -->
      <div class="p-5 border-b border-slate-800 flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <div class="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 font-bold shadow-lg shadow-emerald-500/10">
            <i data-lucide="box" class="w-6 h-6"></i>
          </div>
          <div>
            <h1 class="font-bold text-base leading-none text-white tracking-wide">CJH PANEL</h1>
            <span class="text-[10px] text-emerald-400 font-semibold tracking-wider uppercase">Enterprise v2.0</span>
          </div>
        </div>
      </div>

      <!-- Navigation Tabs -->
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

        <button onclick="switchTab('settings')" id="nav-settings" class="nav-btn w-full flex items-center space-x-3 px-3.5 py-2.5 text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 rounded-xl font-medium text-sm transition">
          <i data-lucide="settings" class="w-4 h-4"></i>
          <span>Admin Settings</span>
        </button>
      </nav>
    </div>

    <!-- User Section -->
    <div class="p-3 border-t border-slate-800">
      <div class="flex items-center justify-between p-2.5 rounded-xl bg-slate-800/40 border border-slate-700/40">
        <div class="flex items-center space-x-3 truncate">
          <div class="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold text-xs text-white shrink-0">
            A
          </div>
          <div class="truncate">
            <p class="text-xs font-semibold text-white truncate">Administrator</p>
            <p class="text-[10px] text-slate-400 truncate">admin@cjhpanel.com</p>
          </div>
        </div>
      </div>
    </div>
  </aside>

  <!-- MAIN CONTENT CONTAINER -->
  <main class="flex-1 flex flex-col min-w-0 overflow-y-auto">

    <!-- TOP BAR -->
    <header class="h-16 bg-slate-900/60 border-b border-slate-800 backdrop-blur-md flex items-center justify-between px-6 sticky top-0 z-20">
      <div class="flex items-center space-x-3">
        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse mr-2"></span>
          ONLINE
        </span>
        <h2 class="text-sm font-semibold text-slate-200 hidden sm:block">Minecraft Server #1 <span class="text-slate-500 font-normal">(Port: 25565)</span></h2>
      </div>

      <!-- Power Controls -->
      <div class="flex items-center space-x-2">
        <button onclick="sendPowerAction('start')" class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 shadow-lg shadow-emerald-600/20 transition active:scale-95">
          <i data-lucide="play" class="w-3.5 h-3.5"></i>
          <span>Start</span>
        </button>
        <button onclick="sendPowerAction('restart')" class="px-3 py-1.5 bg-amber-600 hover:bg-amber-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 shadow-lg shadow-amber-600/20 transition active:scale-95">
          <i data-lucide="rotate-cw" class="w-3.5 h-3.5"></i>
          <span>Restart</span>
        </button>
        <button onclick="sendPowerAction('stop')" class="px-3 py-1.5 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 shadow-lg shadow-rose-600/20 transition active:scale-95">
          <i data-lucide="square" class="w-3.5 h-3.5"></i>
          <span>Stop</span>
        </button>
      </div>
    </header>

    <!-- CONTENT TABS -->
    <div class="p-6">

      <!-- TAB 1: DASHBOARD & CONSOLE -->
      <div id="tab-dashboard" class="tab-content space-y-6">
        <!-- Live Resource Gauges -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <div class="flex justify-between items-center text-slate-400">
              <span class="text-xs font-semibold uppercase tracking-wider">CPU Load</span>
              <i data-lucide="cpu" class="w-4 h-4 text-emerald-400"></i>
            </div>
            <div class="flex items-baseline justify-between">
              <span class="text-2xl font-bold text-white">0.6%</span>
              <span class="text-xs text-slate-500">4 Cores Allocated</span>
            </div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-emerald-500 h-full rounded-full" style="width: 15%"></div>
            </div>
          </div>

          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <div class="flex justify-between items-center text-slate-400">
              <span class="text-xs font-semibold uppercase tracking-wider">RAM Usage</span>
              <i data-lucide="database" class="w-4 h-4 text-blue-400"></i>
            </div>
            <div class="flex items-baseline justify-between">
              <span class="text-2xl font-bold text-white">1.40 GB</span>
              <span class="text-xs text-slate-500">of 8.01 GB</span>
            </div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-blue-500 h-full rounded-full" style="width: 18%"></div>
            </div>
          </div>

          <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <div class="flex justify-between items-center text-slate-400">
              <span class="text-xs font-semibold uppercase tracking-wider">Disk Storage</span>
              <i data-lucide="hard-drive" class="w-4 h-4 text-purple-400"></i>
            </div>
            <div class="flex items-baseline justify-between">
              <span class="text-2xl font-bold text-white">12.85 GB</span>
              <span class="text-xs text-slate-500">of 30.00 GB</span>
            </div>
            <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
              <div class="bg-purple-500 h-full rounded-full" style="width: 42%"></div>
            </div>
          </div>
        </div>

        <!-- Live Terminal Window -->
        <div class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl flex flex-col h-[450px]">
          <div class="bg-slate-900/90 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <div class="w-3 h-3 rounded-full bg-rose-500/80"></div>
              <div class="w-3 h-3 rounded-full bg-amber-500/80"></div>
              <div class="w-3 h-3 rounded-full bg-emerald-500/80"></div>
              <span class="text-xs text-slate-400 font-mono ml-2">server.log — Interactive Terminal</span>
            </div>
            <button onclick="clearConsole()" class="text-xs text-slate-400 hover:text-white flex items-center space-x-1">
              <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
              <span>Clear</span>
            </button>
          </div>

          <div id="console-output" class="flex-1 bg-slate-950 p-4 font-mono text-xs overflow-y-auto space-y-1.5 text-slate-300">
            <p class="text-slate-500">[12:00:01 INFO]: Loading server properties...</p>
            <p class="text-slate-500">[12:00:02 INFO]: Starting Minecraft server on *:25565</p>
            <p class="text-emerald-400">[12:00:05 INFO]: Preparing level "world"</p>
            <p class="text-emerald-400">[12:00:08 INFO]: Done (6.21s)! For help, type "help"</p>
          </div>

          <div class="p-3 bg-slate-900 border-t border-slate-800">
            <form class="flex items-center space-x-2" onsubmit="handleConsoleInput(event)">
              <span class="font-mono text-emerald-400 font-bold pl-2">&gt;</span>
              <input 
                id="console-input"
                type="text" 
                placeholder="Type command here (e.g., op Steve, gamemode creative)..." 
                class="flex-1 bg-transparent border-none text-xs text-slate-200 focus:outline-none font-mono placeholder-slate-600"
              />
              <button type="submit" class="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-medium border border-slate-700 transition">
                Send
              </button>
            </form>
          </div>
        </div>
      </div>

      <!-- TAB 2: VERSION INSTALLER (INSTALL & CHOOSE) -->
      <div id="tab-installer" class="tab-content hidden space-y-6">
        <div>
          <h3 class="text-lg font-bold text-white">Select & Install Server Jar</h3>
          <p class="text-xs text-slate-400">Choose your preferred server software software engine to auto-install.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- PaperMC Card -->
          <div class="bg-slate-900 border border-slate-800 hover:border-emerald-500/50 p-5 rounded-2xl flex flex-col justify-between transition group">
            <div class="space-y-3">
              <div class="w-10 h-10 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400 font-bold">
                <i data-lucide="layers" class="w-5 h-5"></i>
              </div>
              <h4 class="font-bold text-white group-hover:text-emerald-400 transition">PaperMC</h4>
              <p class="text-xs text-slate-400 leading-relaxed">High performance Spigot fork designed to fix lag and boost server efficiency.</p>
            </div>
            <div class="mt-6 space-y-3">
              <select id="paper-version" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="1.20.4">Paper 1.20.4 (Latest)</option>
                <option value="1.20.2">Paper 1.20.2</option>
                <option value="1.19.4">Paper 1.19.4</option>
                <option value="1.16.5">Paper 1.16.5</option>
              </select>
              <button onclick="installJar('PaperMC', 'paper-version')" class="w-full py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-semibold transition shadow-lg shadow-emerald-600/20">
                Install Paper
              </button>
            </div>
          </div>

          <!-- Purpur Card -->
          <div class="bg-slate-900 border border-slate-800 hover:border-emerald-500/50 p-5 rounded-2xl flex flex-col justify-between transition group">
            <div class="space-y-3">
              <div class="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400 font-bold">
                <i data-lucide="zap" class="w-5 h-5"></i>
              </div>
              <h4 class="font-bold text-white group-hover:text-emerald-400 transition">Purpur</h4>
              <p class="text-xs text-slate-400 leading-relaxed">Extremely customizable drop-in replacement for Paper with extra gameplay features.</p>
            </div>
            <div class="mt-6 space-y-3">
              <select id="purpur-version" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="1.20.4">Purpur 1.20.4</option>
                <option value="1.20.2">Purpur 1.20.2</option>
              </select>
              <button onclick="installJar('Purpur', 'purpur-version')" class="w-full py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-xl text-xs font-semibold transition shadow-lg shadow-purple-600/20">
                Install Purpur
              </button>
            </div>
          </div>

          <!-- Forge Card -->
          <div class="bg-slate-900 border border-slate-800 hover:border-emerald-500/50 p-5 rounded-2xl flex flex-col justify-between transition group">
            <div class="space-y-3">
              <div class="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
                <i data-lucide="hammer" class="w-5 h-5"></i>
              </div>
              <h4 class="font-bold text-white group-hover:text-emerald-400 transition">Minecraft Forge</h4>
              <p class="text-xs text-slate-400 leading-relaxed">Required for running heavily modded Minecraft servers and custom modpacks.</p>
            </div>
            <div class="mt-6 space-y-3">
              <select id="forge-version" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="1.20.1">Forge 1.20.1</option>
                <option value="1.18.2">Forge 1.18.2</option>
                <option value="1.12.2">Forge 1.12.2</option>
              </select>
              <button onclick="installJar('Forge', 'forge-version')" class="w-full py-2 bg-amber-600 hover:bg-amber-500 text-white rounded-xl text-xs font-semibold transition shadow-lg shadow-amber-600/20">
                Install Forge
              </button>
            </div>
          </div>

          <!-- Bedrock Card -->
          <div class="bg-slate-900 border border-slate-800 hover:border-emerald-500/50 p-5 rounded-2xl flex flex-col justify-between transition group">
            <div class="space-y-3">
              <div class="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 font-bold">
                <i data-lucide="smartphone" class="w-5 h-5"></i>
              </div>
              <h4 class="font-bold text-white group-hover:text-emerald-400 transition">Bedrock (BDS)</h4>
              <p class="text-xs text-slate-400 leading-relaxed">Official Vanilla server software for Pocket Edition, Windows 10, and Consoles.</p>
            </div>
            <div class="mt-6 space-y-3">
              <select id="bedrock-version" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="Latest">Bedrock Latest</option>
              </select>
              <button onclick="installJar('Bedrock BDS', 'bedrock-version')" class="w-full py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-xs font-semibold transition border border-slate-700">
                Install Bedrock
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 3: FILE MANAGER -->
      <div id="tab-files" class="tab-content hidden space-y-4">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-slate-900 p-4 border border-slate-800 rounded-2xl">
          <div>
            <h3 class="text-sm font-bold text-white">File Directory Manager</h3>
            <p class="text-xs text-slate-400">Path: <span class="font-mono text-emerald-400">/home/container/</span></p>
          </div>
          <div class="flex items-center space-x-2 w-full sm:w-auto">
            <input type="file" id="file-upload" class="hidden" onchange="handleFileUpload(this)">
            <label for="file-upload" class="cursor-pointer px-3.5 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 rounded-xl text-xs font-medium flex items-center space-x-2 transition">
              <i data-lucide="upload-cloud" class="w-4 h-4"></i>
              <span>Upload File</span>
            </label>
            <button onclick="createNewFile()" class="px-3.5 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-semibold flex items-center space-x-2 transition">
              <i data-lucide="plus" class="w-4 h-4"></i>
              <span>New File</span>
            </button>
          </div>
        </div>

        <!-- File Table -->
        <div class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-slate-950/50 border-b border-slate-800 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                  <th class="p-4">Name</th>
                  <th class="p-4">Size</th>
                  <th class="p-4">Last Modified</th>
                  <th class="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody id="file-list" class="divide-y divide-slate-800/60 text-xs text-slate-300">
                <tr class="hover:bg-slate-800/30 transition">
                  <td class="p-4 flex items-center space-x-2 font-medium text-white">
                    <i data-lucide="folder" class="w-4 h-4 text-amber-400"></i>
                    <span>plugins</span>
                  </td>
                  <td class="p-4 text-slate-500">4 items</td>
                  <td class="p-4 text-slate-500">2 hours ago</td>
                  <td class="p-4 text-right">
                    <button class="p-1 hover:text-rose-400 transition"><i data-lucide="trash" class="w-4 h-4"></i></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-800/30 transition">
                  <td class="p-4 flex items-center space-x-2 font-medium text-white">
                    <i data-lucide="file-code" class="w-4 h-4 text-emerald-400"></i>
                    <span>server.properties</span>
                  </td>
                  <td class="p-4 text-slate-500">1.2 KB</td>
                  <td class="p-4 text-slate-500">Yesterday</td>
                  <td class="p-4 text-right">
                    <button class="p-1 hover:text-rose-400 transition"><i data-lucide="trash" class="w-4 h-4"></i></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-800/30 transition">
                  <td class="p-4 flex items-center space-x-2 font-medium text-white">
                    <i data-lucide="box" class="w-4 h-4 text-blue-400"></i>
                    <span>server.jar</span>
                  </td>
                  <td class="p-4 text-slate-500">42.8 MB</td>
                  <td class="p-4 text-slate-500">3 days ago</td>
                  <td class="p-4 text-right">
                    <button class="p-1 hover:text-rose-400 transition"><i data-lucide="trash" class="w-4 h-4"></i></button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- TAB 4: SETTINGS -->
      <div id="tab-settings" class="tab-content hidden space-y-6">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4 max-w-xl">
          <h3 class="text-base font-bold text-white">Panel Branding</h3>
          
          <div class="space-y-2">
            <label class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Panel Name</label>
            <input 
              type="text" 
              value="CJH PANEL - Enterprise" 
              class="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500"
            />
          </div>

          <button onclick="alert('Settings Saved Successfully!')" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-semibold transition">
            Save Settings
          </button>
        </div>
      </div>

    </div>
  </main>

  <!-- JAVASCRIPT LOGIC -->
  <script>
    // Initialize Icons
    lucide.createIcons();

    // Tab Switcher
    function switchTab(tabId) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.nav-btn').forEach(el => {
        el.classList.remove('bg-emerald-500/10', 'text-emerald-400', 'border', 'border-emerald-500/20');
        el.classList.add('text-slate-400');
      });

      document.getElementById(`tab-${tabId}`).classList.remove('hidden');
      const activeNav = document.getElementById(`nav-${tabId}`);
      activeNav.classList.add('bg-emerald-500/10', 'text-emerald-400', 'border', 'border-emerald-500/20');
      activeNav.classList.remove('text-slate-400');
    }

    // Power Actions Simulation
    function sendPowerAction(action) {
      const output = document.getElementById('console-output');
      const time = new Date().toLocaleTimeString();
      
      let msg = '';
      if(action === 'start') msg = `<p class="text-emerald-400">[${time} SYSTEM]: Starting server instance...</p>`;
      if(action === 'restart') msg = `<p class="text-amber-400">[${time} SYSTEM]: Server restarting...</p>`;
      if(action === 'stop') msg = `<p class="text-rose-400">[${time} SYSTEM]: Server stopped by operator.</p>`;

      output.innerHTML += msg;
      output.scrollTop = output.scrollHeight;
    }

    // Console Input Handler
    function handleConsoleInput(e) {
      e.preventDefault();
      const input = document.getElementById('console-input');
      const output = document.getElementById('console-output');
      const time = new Date().toLocaleTimeString();

      if (!input.value.trim()) return;

      output.innerHTML += `<p class="text-slate-200">[${time} CONSOLE]: &gt; ${input.value}</p>`;
      input.value = '';
      output.scrollTop = output.scrollHeight;
    }

    function clearConsole() {
      document.getElementById('console-output').innerHTML = '';
    }

    // Auto-Installer Simulation
    function installJar(software, selectId) {
      const version = document.getElementById(selectId).value;
      switchTab('dashboard');
      
      const output = document.getElementById('console-output');
      const time = new Date().toLocaleTimeString();

      output.innerHTML += `
        <p class="text-blue-400">[${time} INSTALLER]: Downloading ${software} (${version})...</p>
        <p class="text-emerald-400">[${time} INSTALLER]: Software successfully unpacked to server.jar!</p>
      `;
      output.scrollTop = output.scrollHeight;
    }

    // File Upload Handler
    function handleFileUpload(input) {
      if (input.files && input.files[0]) {
        const file = input.files[0];
        const tbody = document.getElementById('file-list');
        
        tbody.innerHTML += `
          <tr class="hover:bg-slate-800/30 transition">
            <td class="p-4 flex items-center space-x-2 font-medium text-white">
              <i data-lucide="file" class="w-4 h-4 text-emerald-400"></i>
              <span>${file.name}</span>
            </td>
            <td class="p-4 text-slate-500">${(file.size / 1024).toFixed(1)} KB</td>
            <td class="p-4 text-slate-500">Just now</td>
            <td class="p-4 text-right">
              <button class="p-1 hover:text-rose-400 transition"><i data-lucide="trash" class="w-4 h-4"></i></button>
            </td>
          </tr>
        `;
        lucide.createIcons();
        alert(`Uploaded: ${file.name}`);
      }
    }

    function createNewFile() {
      const fileName = prompt("Enter new file name (e.g. eula.txt):");
      if (fileName) {
        const tbody = document.getElementById('file-list');
        tbody.innerHTML += `
          <tr class="hover:bg-slate-800/30 transition">
            <td class="p-4 flex items-center space-x-2 font-medium text-white">
              <i data-lucide="file-text" class="w-4 h-4 text-blue-400"></i>
              <span>${fileName}</span>
            </td>
            <td class="p-4 text-slate-500">0 B</td>
            <td class="p-4 text-slate-500">Just now</td>
            <td class="p-4 text-right">
              <button class="p-1 hover:text-rose-400 transition"><i data-lucide="trash" class="w-4 h-4"></i></button>
            </td>
          </tr>
        `;
        lucide.createIcons();
      }
    }
  </script>
</body>
</html>
