# OpenClaw Hardened Edition - Windows Setup Guide

## 🎯 What You're Building

A maximum-security AI agent that:
- ✅ Runs on your Windows laptop
- ✅ Requires dual-password approval (Gmail + Telegram) for ALL actions
- ✅ Only accepts commands from YOU
- ✅ Creates drafts for everything, publishes only with your approval
- ✅ Protects against prompt injection attacks
- ✅ Accessible from your Android phone via WebUI
- ✅ Sandboxed in Docker with network restrictions

---

## 📋 Prerequisites

### Hardware
- Windows 10/11 laptop
- Minimum 8GB RAM (16GB recommended)
- 50GB free disk space
- Stable internet connection

### Accounts You'll Need
1. Gmail account (thrivelo.ceo@gmail.com) - **You already have this**
2. Telegram account with phone +1-902-317-2861 - **You already have this**
3. Anthropic API key (for Claude)

---

## 🧹 PART 1: Clean Your Laptop

### Option A: Fresh Windows Install (Recommended)

**⚠️ BACKUP YOUR DATA FIRST!**

1. **Backup everything important:**
   - Documents → External SSD or Google Drive
   - Photos → Google Photos or External SSD
   - Browser bookmarks → Export to HTML file
   - Password manager export

2. **Create Windows 11 Installation Media:**
   - Visit: https://www.microsoft.com/software-download/windows11
   - Download "Media Creation Tool"
   - Run it, choose "Create installation media"
   - Use an 8GB+ USB drive

3. **Clean Install:**
   - Restart laptop with USB plugged in
   - Boot from USB (usually press F12 or DEL during startup)
   - Choose "Custom: Install Windows only (advanced)"
   - Delete ALL partitions
   - Install on unallocated space
   - **Skip Microsoft account** - use local account instead
   - **Disable all telemetry** during setup

### Option B: Targeted Cleanup (Faster, less secure)

If you don't want to reinstall Windows:

1. **Uninstall unnecessary software:**
   - Go to Settings → Apps → Installed apps
   - Remove: Games, bloatware, unused programs
   - Keep: Browser, essential work apps

2. **Disable startup programs:**
   - Press Ctrl+Shift+Esc (Task Manager)
   - Go to "Startup" tab
   - Disable everything except antivirus

3. **Clean temp files:**
   - Open "Disk Cleanup" (search in Start menu)
   - Clean system files
   - Delete Windows Update cleanup files

---

## 💻 PART 2: Install Required Software

### Step 1: Install Node.js

1. Go to: https://nodejs.org
2. Download the **LTS version** (currently v20.x)
3. Run installer
4. ✅ Check "Automatically install necessary tools"
5. Complete installation
6. **Verify:**
   ```cmd
   node --version
   npm --version
   ```

### Step 2: Install Git

1. Go to: https://git-scm.com/download/win
2. Download and install
3. Use default settings
4. **Verify:**
   ```cmd
   git --version
   ```

### Step 3: Install Docker Desktop

1. Go to: https://www.docker.com/products/docker-desktop/
2. Download Docker Desktop for Windows
3. Install (requires restart)
4. Open Docker Desktop
5. Go to Settings:
   - ✅ Enable "Use WSL 2 based engine"
   - Resources → Set Memory to 4GB minimum
6. **Verify:**
   ```cmd
   docker --version
   docker-compose --version
   ```

### Step 4: Install Visual Studio Code (Optional)

Good for viewing/editing code:
- https://code.visualstudio.com/

---

## 🔐 PART 3: Set Up Authentication

### Gmail App Password (for Password A delivery)

1. **Enable 2-Factor Authentication:**
   - Go to: https://myaccount.google.com/security
   - Turn on "2-Step Verification"
   - Follow the prompts

2. **Create App Password:**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Windows Computer"
   - Name it: "OpenClaw Agent"
   - Copy the 16-character password (format: xxxx xxxx xxxx xxxx)
   - **Save this** - you'll need it in Step 5

### Telegram Bot Setup (for Password B delivery)

1. **Create a Bot:**
   - Open Telegram
   - Search for: @BotFather
   - Send: `/newbot`
   - Name: "OpenClaw Password Bot"
   - Username: "YourName_OpenClaw_bot" (must end with _bot)
   - **Copy the Bot Token** (format: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)

2. **Get Your Chat ID:**
   - Search for: @userinfobot
   - Start a chat
   - It will reply with your User ID (a number like 123456789)
   - **Copy this** - this is your TELEGRAM_OWNER_CHAT_ID

3. **Activate Your Bot:**
   - Search for your bot username in Telegram
   - Click "START"

### Anthropic API Key

1. Go to: https://console.anthropic.com/
2. Create account / Sign in
3. Go to "API Keys"
4. Create new key
5. **Copy the key** (starts with sk-ant-)

---

## 🚀 PART 4: Install Hardened OpenClaw

### Step 1: Get the Code

Open Command Prompt (CMD) or PowerShell:

```cmd
cd C:\
mkdir openclaw-hardened
cd openclaw-hardened

# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git .
git checkout v2026.1.29
```

### Step 2: Apply Security Overlay

Extract the `openclaw-hardened-overlay` folder you received into the OpenClaw directory:

```cmd
# Your folder structure should now look like:
C:\openclaw-hardened\
  ├── auth/                    (security modules)
  ├── security/                (security modules)
  ├── config/                  (hardened config)
  ├── docker/                  (Docker files)
  ├── src/                     (OpenClaw core)
  ├── package.json
  └── ...
```

### Step 3: Create .env File

Create a file named `.env` in `C:\openclaw-hardened\`:

```env
# Owner Configuration
OWNER_EMAIL=thrivelo.ceo@gmail.com
OWNER_TELEGRAM=+19023172861

# Gmail (Password A delivery)
GMAIL_USER=thrivelo.ceo@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx

# Telegram (Password B delivery)
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_OWNER_CHAT_ID=123456789

# Claude API
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx

# Security
SECURITY_MODE=hardened
DRAFT_MODE=enabled
SINGLE_OWNER_MODE=enabled

# Network
GATEWAY_HOST=0.0.0.0
GATEWAY_PORT=3000
```

**Replace** the `xxxx` placeholders with your actual credentials from Part 3.

### Step 4: Install Dependencies

```cmd
npm install
```

This will take 5-10 minutes.

### Step 5: Build the Application

```cmd
npm run build
```

---

## 🐳 PART 5: Run in Docker

### Build the Container

```cmd
docker-compose -f docker/docker-compose.yml build
```

### Start OpenClaw

```cmd
docker-compose -f docker/docker-compose.yml up -d
```

### Check if Running

```cmd
docker ps
```

You should see `openclaw-hardened` running.

### View Logs

```cmd
docker-compose -f docker/docker-compose.yml logs -f
```

---

## 📱 PART 6: Access from Android

### Option 1: Local Network Access (Easiest)

1. **Find your laptop's IP address:**
   ```cmd
   ipconfig
   ```
   Look for "IPv4 Address" (usually 192.168.x.x)

2. **On your Android:**
   - Open Chrome
   - Go to: `http://192.168.x.x:3000`
   - (Replace with your laptop's IP)

### Option 2: Tailscale VPN (More Secure)

1. **Install Tailscale on laptop:**
   - Go to: https://tailscale.com/download/windows
   - Install and sign up

2. **Install Tailscale on Android:**
   - Install from Play Store
   - Sign in with same account

3. **Access OpenClaw:**
   - Your laptop will have a Tailscale hostname
   - Access via: `http://laptop-name:3000`

---

## ✅ PART 7: First Boot & Testing

### Test Password System

1. **Send a test command** (from WebUI or Telegram):
   ```
   Create an Instagram post about our new product
   ```

2. **You should receive:**
   - 📧 Email to thrivelo.ceo@gmail.com with Password A
   - 📱 Telegram message with Password B

3. **OpenClaw will show:**
   ```
   ⏳ Awaiting initiation passwords
   Task ID: task_1234567890_abc123
   ```

4. **Enter both passwords:**
   - In WebUI: Enter Password A and Password B
   - Click "Start Task"

5. **Agent creates the post as DRAFT**

6. **You receive completion passwords:**
   - 📧 Email with Password C
   - 📱 Telegram with Password D

7. **Review the draft, then:**
   - Enter Password C and Password D
   - Click "Publish"

8. **Post goes live!** ✅

---

## 🔧 Troubleshooting

### "Cannot connect to Docker"
- Open Docker Desktop
- Make sure it's running (green icon in taskbar)
- Restart Docker if needed

### "Port 3000 already in use"
- Something else is using port 3000
- Change in docker-compose.yml: `"127.0.0.1:3001:3000"`

### "Gmail password not working"
- Make sure 2FA is enabled first
- Use App Password, not your regular password
- Remove spaces from the password in .env

### "Telegram bot not sending"
- Make sure you clicked START in the bot chat
- Verify Bot Token is correct
- Check CHAT_ID matches your user ID

### "Cannot access from Android"
- Make sure laptop and phone are on same WiFi
- Check Windows Firewall isn't blocking port 3000
- Try: Windows Defender Firewall → Allow an app

---

## 🎉 You're Done!

Your hardened OpenClaw is now running with:
- ✅ Dual-password protection
- ✅ Draft-only mode
- ✅ Single-owner access control
- ✅ Prompt injection defense
- ✅ Sandboxed environment
- ✅ Mobile access

## 📞 Support

If you get stuck, the logs will help:
```cmd
docker-compose -f docker/docker-compose.yml logs -f openclaw-hardened
```

Common issues and solutions are in the logs.

---

**Security Note:** Never share your .env file or passwords with anyone!
