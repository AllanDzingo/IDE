# 🚀 kiyoh-custom-ide — Self-Hosted Codespaces Alternative on Fly.io

Run **code-server** (VS Code in the browser) on [Fly.io](https://fly.io) with automatic **scale-to-zero** — a cost-effective, self-hosted alternative to GitHub Codespaces.

Your development environment spins up on-demand when you visit the URL, and shuts down after inactivity. You pay **only for the minutes you use** (~$0.0015/min for a shared-cpu-1x VM).

**Also supports:**
- **VS Code Remote-SSH** — Connect your local VS Code directly to the Fly.io instance
- **Dev Containers** — Open the repo in a local container matching the deployment environment
- **VS Code Tunnels** — Use the `code-server tunnel` command from within the browser IDE

---

## 📋 Prerequisites

- [Fly.io CLI (`flyctl`)](https://fly.io/docs/hands-on/install-flyctl/) installed and authenticated (`fly auth login`)
- [Docker](https://docs.docker.com/engine/install/) installed locally (for testing builds)
- [Git](https://git-scm.com/) installed
- [VS Code](https://code.visualstudio.com/) with the **Remote - SSH** extension (for SSH connections)

---

## 🚀 Quick Start — Deploy in 5 Minutes

### 1. Clone This Repository

```bash
git clone <your-repo-url>
cd kiyoh-custom-ide
```

### 2. Launch the Fly App

```bash
# Launch (creates the app on Fly.io, asks you to name it)
fly launch --no-deploy
```

> When prompted:
> - **App name**: `kiyoh-custom-ide` (or choose something unique)
> - **Region**: Pick one closest to you (`ams` for Europe/Africa, `iad` for US East, `sin` for Asia)
> - **Would you like to set up a Postgres database?**: **No**
> - **Would you like to deploy now?**: **No** (we need to set up the volume first)

### 3. Set Your Password

```bash
fly secrets set PASSWORD="your-strong-password-here"
```

### 4. Create a Persistent Volume (10GB)

```bash
fly volumes create workspace_data --region ams --size 10
```

> Replace `ams` with the region you chose in step 2.

### 5. Deploy!

```bash
fly deploy
```

Wait ~2-3 minutes for the build and deployment to complete.

### 6. Open Your Codespace

```bash
fly open
```

Or visit `https://kiyoh-custom-ide.fly.dev` in your browser.

> **Login with the password you set in step 3.**

---

## ⚙️ Scale-to-Zero (Auto-Sleep/Wake)

This is configured out-of-the-box in `fly.toml`:

```toml
[http_service]
  auto_stop_machines = true    # Stop machine after ~5 min of inactivity
  auto_start_machines = true   # Start machine when HTTP request arrives
  min_machines_running = 0     # Allow 0 machines when idle
```

**How it works:**
- After **~5 minutes of no HTTP traffic**, Fly.io automatically suspends your machine
- When you visit the URL again, the machine starts automatically (takes ~10-15 seconds)
- You pay **nothing** while the machine is stopped

**To check if your machine is running:**
```bash
fly machine list
```

**To manually stop/start:**
```bash
fly machine stop <machine-id>
fly machine start <machine-id>
```

---

## 📂 Persistent Storage

Your work is stored on a **10GB persistent volume** mounted at `/home/coder/workspace` inside the container.

- ✅ Cloned repos survive restarts
- ✅ VS Code extensions survive restarts
- ✅ Code changes persist
- ❌ The container filesystem outside `/home/coder/workspace` is ephemeral

**To add more storage:**
```bash
fly volumes extend workspace_data --size 20   # Extend to 20GB
```

---

## 🔗 Connect Local VS Code (Multiple Methods)

### Method 1: VS Code Remote - SSH (Recommended)

The Dockerfile includes an SSH server on port **2222** for direct VS Code Remote-SSH connections.

**Step 1: Add SSH config to your local machine**

Add the following to `~/.ssh/config` (on Windows: `C:\Users\<YourUser>\.ssh\config`):

```ssh-config
Host kiyoh-custom-ide
  HostName kiyoh-custom-ide.fly.dev
  Port 2222
  User coder
  PreferredAuthentications password
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

> **Note:** `StrictHostKeyChecking no` is needed because Fly.io machines get new IPs on restart. For production, you can manage known hosts manually.

**Step 2: Connect in VS Code**

1. Open VS Code
2. Press `F1` → **Remote-SSH: Connect to Host...**
3. Select `kiyoh-custom-ide`
4. Enter the password you set with `fly secrets set PASSWORD=...`
5. VS Code will install the server and connect

**Step 3: Open the workspace**

Once connected, open `/home/coder/workspace` as your workspace folder.

### Method 2: Fly.io SSH Tunnel

```bash
fly ssh console
# Inside the container, start the SSH server (it starts automatically)
# Then from another terminal, connect via SSH:
ssh coder@localhost -p 2222
```

### Method 3: code-server Tunneling

code-server supports VS Code Remote Tunnel out-of-the-box. From within the browser IDE, open a terminal and run:

```bash
code-server tunnel
```

Follow the prompts to authenticate and connect.

### Method 4: Dev Containers (Local)

This repository includes a `.devcontainer/devcontainer.json` configuration. To use it:

1. Install the **Remote - Containers** extension in VS Code
2. Press `F1` → **Dev Containers: Reopen in Container**
3. VS Code will build the container using the Dockerfile and open the project inside it

This gives you a local development environment that matches the Fly.io deployment.

---

## 🔧 Common Tasks

### View Logs
```bash
fly logs
```

### SSH into Your Codespace
```bash
fly ssh console
```

### Update code-server Version
Edit the `CODE_SERVER_VERSION` ARG in the `Dockerfile` and re-deploy:
```bash
fly deploy
```

### Install Additional Tools
SSH in and install anything you need:
```bash
fly ssh console
sudo apt-get install <package-name>
```

> **Note:** Installed packages outside `/home/coder/workspace` are ephemeral. To make them permanent, update the `Dockerfile` and re-deploy.

### Scale Up (More CPU/RAM)
Edit `fly.toml`:
```toml
[[vm]]
  cpu_kind = "shared"
  cpus = 2          # 2 CPUs
  memory_mb = 2048  # 2GB RAM
```

Then:
```bash
fly deploy
```

---

## 🛡️ Security Best Practices

1. **Use a strong password:** `fly secrets set PASSWORD="<strong-password>"`
2. **Rotate passwords periodically**
3. **Don't hardcode secrets** — always use `fly secrets set`
4. **Enable HTTPS** (already configured in `fly.toml` with `force_https = true`)
5. **Consider adding IP restrictions:** See [Fly.io HTTP Services docs](https://fly.io/docs/reference/configuration/#the-http_service-section)
6. **SSH key authentication:** For production, consider setting up SSH key-based auth instead of password

---

## 💰 Cost Breakdown

| Component | Cost |
|-----------|------|
| Shared CPU 1x VM | $0.0015/min (~$2.16/month if 24/7) |
| 10GB Persistent Volume | $0.15/GB/month = $1.50/month |
| **Total if idle** | **$0** (scale-to-zero stops the VM) |
| **Total if active 40 hrs/week** | **~$1.44/month + $1.50 = ~$2.94/month** |

Compare to GitHub Codespaces 2-core: **$22.72/month** for 40 hrs/week.

---

## 🧪 Local Testing (Optional)

Test the Docker image locally before deploying:

```bash
# Build
docker build -t kiyoh-custom-ide .

# Run (replace with your password)
docker run -it --rm \
  -p 8080:8080 \
  -p 2222:2222 \
  -e PASSWORD="test123" \
  -v "${PWD}/workspace:/home/coder/workspace" \
  kiyoh-custom-ide

# Open in browser
open http://localhost:8080

# Or connect via SSH
ssh coder@localhost -p 2222
```

---

## 📁 Repository Structure

```
.
├── .devcontainer/
│   └── devcontainer.json    # Dev Container configuration for local VS Code
├── .vscode/
│   ├── extensions.json      # Recommended VS Code extensions
│   └── settings.json        # Workspace settings for remote development
├── Dockerfile               # Multi-stage Docker build for code-server + SSH
├── fly.toml                 # Fly.io configuration (scale-to-zero, volumes, ports)
├── .gitignore               # Git ignore rules
└── README.md                # This file
```

---

## 🧹 Teardown (Delete Everything)

```bash
# Stop the machine
fly machine list
fly machine stop <machine-id>

# Delete the app (this deletes the app and all its resources)
fly apps destroy kiyoh-custom-ide

# Delete the volume
fly volumes delete workspace_data
```

---

## 📚 Resources

- [code-server Documentation](https://coder.com/docs/code-server/latest)
- [Fly.io Documentation](https://fly.io/docs/)
- [Fly Machines: Scale to Zero](https://fly.io/docs/reference/scale-to-zero/)
- [Fly Volumes](https://fly.io/docs/reference/volumes/)
- [VS Code Remote-SSH](https://code.visualstudio.com/docs/remote/ssh)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/remote/containers)