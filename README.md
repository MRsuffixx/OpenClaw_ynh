# OpenClaw for YunoHost

[![Integration level](https://dash.yunohost.org/integration/openclaw.svg)](https://dash.yunohost.org/appci/app/openclaw) ![Maintenance status](https://ci-apps.yunohost.org/ci/badges/openclaw.maintain.svg)

*[Lire ce readme en français.](./README_fr.md)*

> OpenClaw is a self-hosted AI gateway and agentic runtime that connects multi-channel messaging platforms through a unified gateway, with support for autonomous AI agents.

## Overview

OpenClaw is an AI gateway and agentic runtime that runs on your own server. It exposes a WebSocket/HTTP gateway on `127.0.0.1:18789`, designed to be accessed exclusively through NGINX with TLS termination and YunoHost SSO passthrough.

### Key Features

- **Multi-channel messaging**: Connect Telegram bots, Discord integrations, Slack, email, and other messaging platforms
- **Agentic workflows**: Deploy AI agents that can reason, use tools, and execute tasks autonomously
- **WebSocket/HTTP gateway**: Flexible API with bidirectional streaming for external integrations
- **YunoHost integration**: Automatic SSO authentication via your YunoHost user credentials
- **Self-hosted**: Full control over your data and infrastructure
- **Multi-instance**: Run multiple independent instances on one YunoHost server

## Limitations

- The `dev` update channel is not supported by this package
- 32-bit ARM (`armhf`) is not supported — only `amd64` and `arm64`
- The gateway binds exclusively to `127.0.0.1` and is never exposed directly to the internet

## Requirements

- YunoHost 11.2 or later
- Architecture: `amd64` or `arm64`
- At least 1 GB free disk space
- 512 MB RAM for installation, 256 MB for runtime

## Installation

### From the YunoHost admin panel

1. Log in to your YunoHost admin interface
2. Navigate to **Apps** → **Install**
3. Search for "OpenClaw" and click **Install**
4. Fill in the installation arguments:
   - **Domain**: Choose a domain or subdomain
   - **Path**: Typically `/`
   - **Update channel**: `stable` (recommended) or `beta`
   - **OpenClaw version**: `latest` for automatic latest stable release, or specify a version
   - **Gateway auth token**: Leave empty to auto-generate, or provide your own (min. 16 characters)
   - **Enable automatic updates**: `no` (recommended) or `yes`
5. Click **Install**

### From the command line

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh
```

### Testing the development version

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Configuration

After installation, access the config panel from **Apps** → **OpenClaw** → **Config panel** to manage:

- **Update channel**: Switch between `stable` and `beta`
- **Auto-update**: Enable or disable automatic updates
- **Gateway auth token**: Update the shared secret for API access

## Usage

### Accessing the gateway

Open `https://your-domain.com/` in your browser. Authentication is automatic via YunoHost SSO — log in with your YunoHost credentials.

### CLI commands

Run OpenClaw commands as the app user:

```bash
sudo -u openclaw openclaw <command>
```

For multi-instance installations, use the instance name (e.g., `openclaw__2`):

```bash
sudo -u openclaw__2 openclaw <command>
```

### Common commands

| Command | Description |
|---------|-------------|
| `openclaw gateway start` | Start the gateway |
| `openclaw gateway stop` | Stop the gateway |
| `openclaw gateway restart` | Restart the gateway |
| `openclaw channel add <name>` | Add a messaging channel |
| `openclaw doctor` | Run health diagnostics |
| `openclaw --version` | Show installed version |

### Health check

```bash
curl http://127.0.0.1:18789/readyz
```

### Logs

| Log | Path |
|-----|------|
| Gateway stdout | `/var/log/openclaw/openclaw.log` |
| Gateway stderr | `/var/log/openclaw/error.log` |
| Install log | `/var/log/openclaw/install.log` |
| Upgrade log | `/var/log/openclaw/upgrade.log` |

## Upgrade

### From the admin panel

Navigate to **Apps** → **OpenClaw** → **Update**

### From the command line

```bash
sudo yunohost app upgrade openclaw
```

To upgrade to the testing version:

```bash
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Backup and Restore

### Creating a backup

```bash
sudo yunohost backup create --apps openclaw
```

This includes the full data directory with all credentials and agent state.

### Restoring from backup

```bash
sudo yunohost backup restore <backup_name> --apps openclaw
```

### Data preservation

- The data directory (`/home/openclaw/.openclaw/`) is **retained** after app removal
- Use `--purge` with `yunohost app remove openclaw --purge` to delete all data permanently
- Automatic safety-backup-before-upgrade does **not** include the data directory (it may be large)

## Removal

```bash
sudo yunohost app remove openclaw
```

This removes the application but preserves your data. To remove all data:

```bash
sudo yunohost app remove openclaw --purge
```

## Architecture

```
Browser / YunoHost SSO
        │
        ▼
   NGINX (TLS termination, SSO header injection)
        │  X-Remote-User: <ldap_uid>
        │  X-Remote-Email: <email>
        │  Upgrade: websocket
        ▼
   OpenClaw Gateway (127.0.0.1:18789)
        │
        ├── ~/.openclaw/openclaw.json     (runtime config)
        ├── ~/.openclaw/credentials/      (channel tokens)
        ├── ~/.openclaw/agents/           (agent state)
        └── ~/.openclaw/workspace/        (skills, memories)
```

## Documentation and resources

- **Upstream documentation**: https://docs.openclaw.ai
- **Upstream website**: https://openclaw.ai
- **Upstream code**: https://github.com/openclaw/openclaw
- **YunoHost packaging documentation**: https://doc.yunohost.org/dev/packaging/
- **Report a bug**: https://github.com/MRsuffixx/OpenClaw_ynh/issues

## Contributing

Please send pull requests to the `testing` branch.

To try the testing branch:

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Shipped version

**OpenClaw version**: 1.0~ynh1

---

*More info regarding app packaging:* https://doc.yunohost.org/dev/packaging/