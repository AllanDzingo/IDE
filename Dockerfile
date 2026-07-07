# ===========================================================
# code-server on Fly.io — Multi-stage Dockerfile
# Acts as a self-hosted, cost-effective Codespaces alternative
# ===========================================================

# ── Stage 1: Builder ──────────────────────────────────────
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install code-server from the official deb package
ARG CODE_SERVER_VERSION=4.97.3
RUN curl -fSL \
    "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb" \
    -o /tmp/code-server.deb \
    && dpkg -i /tmp/code-server.deb \
    && rm /tmp/code-server.deb

# ── Stage 2: Runtime ──────────────────────────────────────
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    # code-server listens on this port inside the container
    CODE_SERVER_PORT=8080

# Install essential development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tooling
    ca-certificates \
    curl \
    wget \
    git \
    openssh-client \
    # Build essentials (C/C++, make, etc.)
    build-essential \
    pkg-config \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Node.js from NodeSource
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    # Useful CLI utilities
    unzip \
    zip \
    htop \
    jq \
    ripgrep \
    fd-find \
    tmux \
    tree \
    nano \
    vim \
    # Clean up
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn

# Copy code-server from the builder stage
COPY --from=builder /usr/bin/code-server /usr/bin/code-server
COPY --from=builder /usr/lib/code-server /usr/lib/code-server

# Create the coder user (non-root) for security
RUN groupadd --gid 1000 coder \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash coder \
    && usermod -aG sudo coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

# Ensure workspace directory exists (Fly volume will mount here)
RUN mkdir -p /home/coder/workspace /home/coder/.config/code-server \
    && chown -R coder:coder /home/coder

# Set the web-server port for code-server
EXPOSE 8080

# Switch to non-root user
USER coder
WORKDIR /home/coder/workspace

# Configure code-server to use password auth (value from $PASSWORD env var)
# and bind to 0.0.0.0 so Fly proxy can reach it
RUN mkdir -p /home/coder/.config/code-server \
    && echo "bind-addr: 0.0.0.0:8080" > /home/coder/.config/code-server/config.yaml \
    && echo "auth: password" >> /home/coder/.config/code-server/config.yaml \
    && echo "password: \${PASSWORD}" >> /home/coder/.config/code-server/config.yaml \
    && echo "cert: false" >> /home/coder/.config/code-server/config.yaml \
    && echo "disable-telemetry: true" >> /home/coder/.config/code-server/config.yaml

# Health check — ensures Fly.io knows the app is alive
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Start code-server
CMD ["code-server", "--config", "/home/coder/.config/code-server/config.yaml"]