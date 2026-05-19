# Before Upgrading OpenClaw

## Pre-Upgrade Notes

Before upgrading OpenClaw, note the following:

- **Backup recommended**: Run `yunohost backup create --apps openclaw` before upgrading
- **Service interruption**: The gateway will be stopped during the upgrade
- **Data directory preserved**: The data directory (`/home/__APP__/.openclaw/`) is NOT included in automatic safety backups
- **Configuration changes**: User-modified settings in `openclaw.json` will be preserved if possible

## Upgrade Process

1. The upgrade script stops the gateway service
2. Downloads and runs the new OpenClaw version via `openclaw update` or `install-cli.sh`
3. Re-renders all configuration files
4. Runs `openclaw doctor --fix` to repair any issues
5. Restarts the gateway and verifies health

## What is Preserved

- Channel credentials in `~/.openclaw/credentials/`
- Agent state in `~/.openclaw/agents/`
- Workspace data in `~/.openclaw/workspace/`
- User-modified `openclaw.json` settings (backed up before overwrite)

## What May Change

- Internal OpenClaw file structure
- Default values in `openclaw.json`
- Systemd service unit parameters