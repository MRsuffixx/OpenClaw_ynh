# After Upgrading OpenClaw

## Upgrade Complete

Your OpenClaw instance has been upgraded successfully.

## Post-Upgrade Checklist

1. **Verify gateway is running**: `curl http://127.0.0.1:__PORT__/readyz`
2. **Check version**: `sudo -u __APP__ openclaw --version`
3. **Run doctor**: `sudo -u __APP__ openclaw doctor`
4. **Verify logs**: Check `/var/log/__APP__/upgrade.log` for any issues

## If Issues Occur

If the gateway fails to start after upgrade:

1. Check error log: `tail -50 /var/log/__APP__/error.log`
2. Restore config from backup: Config files are backed up as `openclaw.json.pre-upgrade.*`
3. Restart service: `yunohost service restart __APP__`
4. Run doctor: `sudo -u __APP__ openclaw doctor --fix`

## Rollback

If the upgrade fails completely, restore from the backup created before upgrade:

```bash
yunohost backup restore <backup_name> --apps __APP__
```

## Logs

View upgrade logs at `/var/log/__APP__/upgrade.log`