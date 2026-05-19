# After Installing OpenClaw

## Installation Complete

Your OpenClaw instance is now installed and running.

## Access Information

- **Gateway URL**: `https://__DOMAIN____PATH__`
- **Gateway Port**: `__PORT__` (bound to 127.0.0.1 only)
- **Install Directory**: `__INSTALL_DIR__`
- **Data Directory**: `__DATA_DIR__`
- **Application ID**: `__APP__`

## Next Steps

1. **Access the gateway**: Open `https://__DOMAIN____PATH__` in your browser
2. **Configure channels**: Add messaging channels via `sudo -u __APP__ openclaw channel add <channel>`
3. **Set up authentication**: The gateway uses YunoHost SSO; log in with your YunoHost credentials
4. **Configure update channel**: Use the YunoHost config panel to select stable/beta channel

## Default Credentials

No default credentials are required — authentication is handled entirely through YunoHost SSO.

## Health Check

Verify the gateway is running:

```bash
curl http://127.0.0.1:__PORT__/readyz
```

## Logs

View logs at `/var/log/__APP__/`:
- `__APP__.log` — Gateway stdout
- `error.log` — Gateway stderr
- `install.log` — Installation log