# OpenClaw Administration Guide

## Accessing the CLI

Run OpenClaw commands as the app user:

```bash
sudo -u openclaw openclaw <command>
```

For multi-instance installations, replace `openclaw` with the instance name (e.g., `openclaw__2`).

## Health Check

Verify the gateway is running:

```bash
curl http://127.0.0.1:18789/readyz
```

## Log Locations

| Log | Path |
|-----|------|
| Gateway stdout | `/var/log/openclaw/openclaw.log` |
| Gateway stderr | `/var/log/openclaw/error.log` |
| Install/upgrade log | `/var/log/openclaw/install.log` |

## Managing Channels

OpenClaw supports connecting multiple messaging channels (Telegram, Discord, etc.). After installing, use the CLI to add channels:

```bash
sudo -u openclaw openclaw channel add telegram
```

Channel credentials are stored in `/home/openclaw/.openclaw/credentials/` and are preserved across upgrades.

## Updating OpenClaw

Updates are handled through the YunoHost package upgrade mechanism:

```bash
yunohost app upgrade openclaw
```

Use the config panel to change the update channel (stable/beta).

## Backup Behavior

- `$data_dir` (`/home/openclaw/.openclaw/`) contains all credentials and agent state
- It is **retained** after app removal (only `--purge` deletes it)
- During safety-backup-before-upgrade, the data directory is **not** included (it may be large)
- Manual backups via `yunohost backup create --apps openclaw` **do** include the data directory

## Troubleshooting

If the gateway fails to start:

1. Check logs: `tail -f /var/log/openclaw/error.log`
2. Run doctor: `sudo -u openclaw openclaw doctor`
3. Restart service: `yunohost service restart openclaw`

For permission issues:

```bash
chown -R openclaw:openclaw /home/openclaw/.openclaw/
```