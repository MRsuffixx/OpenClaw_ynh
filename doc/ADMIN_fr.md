# Guide d'administration OpenClaw

## Accès à la CLI

Exécutez les commandes OpenClaw en tant qu'utilisateur de l'application :

```bash
sudo -u openclaw openclaw <commande>
```

Pour les installations multi-instances, remplacez `openclaw` par le nom de l'instance (par ex. `openclaw__2`).

## Vérification de santé

Vérifiez que la passerelle est en cours d'exécution :

```bash
curl http://127.0.0.1:18789/readyz
```

## Emplacements des journaux

| Journal | Chemin |
|---------|--------|
| Sortie standard de la passerelle | `/var/log/openclaw/openclaw.log` |
| Erreurs de la passerelle | `/var/log/openclaw/error.log` |
| Journal d'installation/upgrade | `/var/log/openclaw/install.log` |
| Journal de restauration | `/var/log/openclaw/restore.log` |
| Journal de changement d'URL | `/var/log/openclaw/change_url.log` |

## Gestion des canaux

OpenClaw prend en charge la connexion de plusieurs canaux de messagerie (Telegram, Discord, etc.). Après l'installation, utilisez la CLI pour ajouter des canaux :

```bash
sudo -u openclaw openclaw channel add telegram
```

Les identifiants des canaux sont stockés dans `/home/openclaw/.openclaw/credentials/` et sont préservés lors des mises à jour et sauvegardes.

## Mise à jour d'OpenClaw

Les mises à jour sont gérées via le mécanisme de mise à niveau du paquet YunoHost :

```bash
yunohost app upgrade openclaw
```

Utilisez le panneau de configuration pour changer le canal de mise à jour (stable/beta). Le canal `dev` n'est pas pris en charge par ce paquet.

## Comportement des sauvegardes

- `$data_dir` (`/home/openclaw/.openclaw/`) contient tous les identifiants, agents et données de l'espace de travail
- Il est **conservé** après la suppression de l'application — seul `--purge` le supprime définitivement
- Lors de safety-backup-before-upgrade, le répertoire de données n'est **pas** inclus (il peut être volumineux)
- Les sauvegardes manuelles via `yunohost backup create --apps openclaw` **incluent** le répertoire de données

## Gestion des services

Démarrez, arrêtez ou redémarrez la passerelle :

```bash
yunohost service start openclaw
yunohost service stop openclaw
yunohost service restart openclaw
```

Vérifiez l'état du service :

```bash
yunohost service status openclaw
```

## Dépannage

Si la passerelle refuse de démarrer :

1. Vérifiez les journaux : `tail -f /var/log/openclaw/error.log`
2. Exécutez doctor : `sudo -u openclaw openclaw doctor`
3. Redémarrez le service : `yunohost service restart openclaw`

Pour les problèmes de permissions :

```bash
chown -R openclaw:openclaw /home/openclaw/.openclaw/
```

## Architecture

La passerelle se lie exclusivement à `127.0.0.1:18789` et n'est jamais exposée directement à Internet. Tout le trafic externe est routé via NGINX, qui gère la terminaison TLS et l'injection d'en-têtes SSO.

```
Navigateur → NGINX (TLS) → Passerelle OpenClaw (127.0.0.1:18789)
```

## Multi-instances

Chaque instance s'exécute en tant qu'utilisateur système distinct (`openclaw`, `openclaw__2`, etc.) avec son propre port, répertoire de données et service systemd. Utilisez `sudo -u openclaw__2` pour les commandes de la deuxième instance.