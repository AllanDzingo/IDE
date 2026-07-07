# 🚀 Self-Hosted Codespaces Alternative on Fly.io

Run **code-server** (VS Code in the browser) on [Fly.io](https://fly.io) with automatic **scale-to-zero** — a cost-effective, self-hosted alternative to GitHub Codespaces.

Your development environment spins up on-demand when you visit the URL, and shuts down after inactivity. You pay **only for the minutes you use** (~$0.0015/min for a shared-cpu-1x VM).

---

## 📋 Prerequisites

- [Fly.io CLI (`flyctl`)](https://fly.io/docs/hands-on/install-flyctl/) installed and authenticated (`fly auth login`)
- [Docker](https://docs.docker.com/engine/install/) installed locally (for testing builds)
- [Git](https://git-scm.com/) installed

---

## 🚀 Quick Start — Deploy in 5 Minutes

### 1. Clone or Create This Repository

```bash
git clone <your-repo-url>
cd <your-repo-name>
```

### 2. Launch the Fly App

```bash
# Launch (creates the app on Fly.io, asks you to name it)
fly launch --no-deploy
```

> When prompted:
> - **App name**: Choose something unique (e.g., `my-codespace`)
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

Or visit `https://<your-app-name>.fly.dev` in your browser.

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
docker build -t codespace-local .

# Run (replace with your password)
docker run -it --rm \
  -p 8080:8080 \
  -e PASSWORD="test123" \
  -v "${PWD}/workspace:/home/coder/workspace" \
  codespace-local

# Open in browser
open http://localhost:8080
```

---

## 📁 Repository Structure

```
.
├── Dockerfile          # Multi-stage Docker build for code-server
├── fly.toml            # Fly.io configuration (scale-to-zero, volumes, ports)
├── .gitignore          # Git ignore rules
└── README.md           # This file
```

---

## 🔗 Connect Local VS Code (via SSH Tunneling)

You can connect your **local VS Code** to the remote code-server instance using SSH tunneling:

### Method 1: Fly.io SSH Tunnel
```bash
fly ssh console
# Inside the container, start code-server's SSH server
sudo service ssh start
```

### Method 2: code-server Tunneling
code-server supports VS Code Remote Tunnel out-of-the-box. From within the browser IDE, open a terminal and run:
```bash
code-server tunnel
```

Follow the prompts to authenticate and connect.

---

## 🧹 Teardown (Delete Everything)

```bash
# Stop the machine
fly machine list
fly machine stop <machine-id>

# Delete the app (this deletes the app and all its resources)
fly apps destroy <app-name>

# Delete the volume
fly volumes delete workspace_data
```

---

## 📚 Resources

- [code-server Documentation](https://coder.com/docs/code-server/latest)
- [Fly.io Documentation](https://fly.io/docs/)
- [Fly Machines: Scale to Zero](https://fly.io/docs/reference/scale-to-zero/)
- [Fly Volumes](https://fly.io/docs/reference/volumes/)