# Before Installing OpenClaw

## Prerequisites

Before installing OpenClaw, ensure your YunoHost server meets the following requirements:

- **YunoHost version**: 11.2 or later
- **Architecture**: `amd64` or `arm64` (Raspberry Pi 4/5 supported; 32-bit ARM not supported)
- **Disk space**: At least 1 GB for Node.js, OpenClaw package, and workspace
- **RAM**: 512 MB for build, 256 MB for runtime

## Important Notes

- OpenClaw binds exclusively to `127.0.0.1:18789` — it is never exposed directly to the internet
- The gateway is accessed through NGINX with TLS termination and SSO passthrough
- Installation is done via the official `install-cli.sh` script which provisions its own Node.js environment
- Data directory (`/home/openclaw/.openclaw/`) is retained on removal; use `--purge` to delete all data

## Pre-installation Checklist

- [ ] YunoHost 11.2+ is installed and working
- [ ] Domain is configured in YunoHost
- [ ] DNS is properly set up for your domain
- [ ] No other application is using port 18789 (or let YunoHost auto-assign a port)
- [ ] You have admin access to YunoHost