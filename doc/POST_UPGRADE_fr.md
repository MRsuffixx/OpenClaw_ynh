# Après la mise à niveau d'OpenClaw

## Mise à niveau terminée

Votre instance OpenClaw a été mise à niveau avec succès.

## Liste de contrôle post-mise à niveau

1. **Vérifiez que la passerelle est en cours d'exécution** : `curl http://127.0.0.1:__PORT__/readyz`
2. **Vérifiez la version** : `sudo -u __APP__ openclaw --version`
3. **Exécutez doctor** : `sudo -u __APP__ openclaw doctor`
4. **Vérifiez les journaux** : Consultez `/var/log/__APP__/upgrade.log` pour tout problème

## Si des problèmes surviennent

Si la passerelle refuse de démarrer après la mise à niveau :

1. Consultez le journal des erreurs : `tail -50 /var/log/__APP__/error.log`
2. Restaurez la configuration à partir de la sauvegarde : Les fichiers de configuration sont sauvegardés en tant que `openclaw.json.pre-upgrade.*`
3. Redémarrez le service : `yunohost service restart __APP__`
4. Exécutez doctor : `sudo -u __APP__ openclaw doctor --fix`

## Rétrogradation

Si la mise à niveau échoue complètement, restaurez à partir de la sauvegarde créée avant la mise à niveau :

```bash
yunohost backup restore <nom_sauvegarde> --apps __APP__
```

## Journaux

Consultez les journaux de mise à niveau dans `/var/log/__APP__/upgrade.log`