# Après l'installation d'OpenClaw

## Installation terminée

Votre instance OpenClaw est maintenant installée et en cours d'exécution.

## Informations d'accès

- **URL de la passerelle** : `https://__DOMAIN____PATH__`
- **Port de la passerelle** : `__PORT__` (lié uniquement à 127.0.0.1)
- **Répertoire d'installation** : `__INSTALL_DIR__`
- **Répertoire de données** : `__DATA_DIR__`
- **ID de l'application** : `__APP__`

## Étapes suivantes

1. **Accédez à la passerelle** : Ouvrez `https://__DOMAIN____PATH__` dans votre navigateur
2. **Configurez les canaux** : Ajoutez des canaux de messagerie via `sudo -u __APP__ openclaw channel add <canal>`
3. **Configurez l'authentification** : La passerelle utilise SSO YunoHost ; connectez-vous avec vos identifiants YunoHost
4. **Configurez le canal de mise à jour** : Utilisez le panneau de configuration YunoHost pour sélectionner le canal stable/beta

## Identifiants par défaut

Aucun identifiant par défaut n'est requis — l'authentification est entièrement gérée via SSO YunoHost.

## Vérification de santé

Vérifiez que la passerelle est en cours d'exécution :

```bash
curl http://127.0.0.1:__PORT__/readyz
```

## Journaux

Consultez les journaux dans `/var/log/__APP__/` :
- `__APP__.log` — Sortie standard de la passerelle
- `error.log` — Erreurs de la passerelle
- `install.log` — Journal d'installation