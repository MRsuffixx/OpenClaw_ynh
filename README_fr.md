# OpenClaw pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/openclaw.svg)](https://dash.yunohost.org/appci/app/openclaw) ![État de maintenance](https://ci-apps.yunohost.org/ci/badges/openclaw.maintain.svg)

> OpenClaw est une passerelle IA auto-hébergée et un runtime d'agents qui connecte plusieurs plateformes de messagerie via une passerelle unifiée, avec support des agents IA autonomes.

## Vue d'ensemble

OpenClaw est une passerelle IA et un runtime d'agents qui fonctionne sur votre propre serveur. Il expose une passerelle WebSocket/HTTP sur `127.0.0.1:18789`, conçue pour être accedée exclusivement via NGINX avec terminaison TLS et passage SSO YunoHost.

### Fonctionnalités principales

- **Messagerie multi-canaux** : Connectez des bots Telegram, des intégrations Discord, Slack, e-mail et d'autres plateformes de messagerie
- **Flux de travail agentiques** : Déployez des agents IA capables de raisonner, d'utiliser des outils et d'exécuter des tâches de manière autonome
- **Passerelle WebSocket/HTTP** : API flexible avec streaming bidirectionnel pour les intégrations externes
- **Intégration YunoHost** : Authentification SSO automatique via vos identifiants utilisateur YunoHost
- **Auto-hébergé** : Contrôle total sur vos données et votre infrastructure
- **Multi-instances** : Exécutez plusieurs instances indépendantes sur un serveur YunoHost

## Limitations

- Le canal de mise à jour `dev` n'est pas pris en charge par ce paquet
- ARM 32 bits (`armhf`) n'est pas pris en charge — uniquement `amd64` et `arm64`
- La passerelle se lie exclusivement à `127.0.0.1` et n'est jamais exposée directement à Internet

## Prérequis

- YunoHost 11.2 ou ultérieur
- Architecture : `amd64` ou `arm64`
- Au moins 1 Go d'espace disque libre
- 512 Mo de RAM pour l'installation, 256 Mo pour l'exécution

## Installation

### Depuis le panneau d'administration YunoHost

1. Connectez-vous à votre interface d'administration YunoHost
2. Accédez à **Apps** → **Installer**
3. Recherchez "OpenClaw" et cliquez sur **Installer**
4. Remplissez les arguments d'installation :
   - **Domaine** : Choisissez un domaine ou un sous-domaine
   - **Chemin** : Typiquement `/`
   - **Canal de mise à jour** : `stable` (recommandé) ou `beta`
   - **Version OpenClaw** : `latest` pour la dernière version stable automatique, ou spécifiez une version
   - **Jeton d'authentification de la passerelle** : Laissez vide pour auto-générer, ou fournissez le vôtre (min. 16 caractères)
   - **Activer les mises à jour automatiques** : `non` (recommandé) ou `oui`
5. Cliquez sur **Installer**

### Depuis la ligne de commande

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh
```

### Tester la version de développement

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Configuration

Après l'installation, accédez au panneau de configuration depuis **Apps** → **OpenClaw** → **Panneau de configuration** pour gérer :

- **Canal de mise à jour** : Basculez entre `stable` et `beta`
- **Mise à jour automatique** : Activez ou désactivez les mises à jour automatiques
- **Jeton d'authentification de la passerelle** : Mettez à jour le secret partagé pour l'accès API

## Utilisation

### Accéder à la passerelle

Ouvrez `https://votre-domaine.com/` dans votre navigateur. L'authentification est automatique via SSO YunoHost — connectez-vous avec vos identifiants YunoHost.

### Commandes CLI

Exécutez les commandes OpenClaw en tant qu'utilisateur de l'application :

```bash
sudo -u openclaw openclaw <commande>
```

Pour les installations multi-instances, utilisez le nom de l'instance (par ex. `openclaw__2`) :

```bash
sudo -u openclaw__2 openclaw <commande>
```

### Commandes courantes

| Commande | Description |
|----------|-------------|
| `openclaw gateway start` | Démarrer la passerelle |
| `openclaw gateway stop` | Arrêter la passerelle |
| `openclaw gateway restart` | Redémarrer la passerelle |
| `openclaw channel add <nom>` | Ajouter un canal de messagerie |
| `openclaw doctor` | Exécuter les diagnostics de santé |
| `openclaw --version` | Afficher la version installée |

### Vérification de santé

```bash
curl http://127.0.0.1:18789/readyz
```

### Journaux

| Journal | Chemin |
|---------|--------|
| Sortie standard de la passerelle | `/var/log/openclaw/openclaw.log` |
| Erreurs de la passerelle | `/var/log/openclaw/error.log` |
| Journal d'installation | `/var/log/openclaw/install.log` |
| Journal de mise à niveau | `/var/log/openclaw/upgrade.log` |

## Mise à niveau

### Depuis le panneau d'administration

Accédez à **Apps** → **OpenClaw** → **Mettre à jour**

### Depuis la ligne de commande

```bash
sudo yunohost app upgrade openclaw
```

Pour mettre à niveau vers la version de test :

```bash
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Sauvegarde et restauration

### Créer une sauvegarde

```bash
sudo yunohost backup create --apps openclaw
```

Cela inclut le répertoire de données complet avec tous les identifiants et l'état des agents.

### Restaurer à partir d'une sauvegarde

```bash
sudo yunohost backup restore <nom_sauvegarde> --apps openclaw
```

### Conservation des données

- Le répertoire de données (`/home/openclaw/.openclaw/`) est **conservé** après la suppression de l'application
- Utilisez `--purge` avec `yunohost app remove openclaw --purge` pour supprimer définitivement toutes les données
- La sauvegarde automatique de sécurité avant mise à niveau ne **inclut pas** le répertoire de données (il peut être volumineux)

## Suppression

```bash
sudo yunohost app remove openclaw
```

Cela supprime l'application mais conserve vos données. Pour supprimer toutes les données :

```bash
sudo yunohost app remove openclaw --purge
```

## Architecture

```
Navigateur / SSO YunoHost
        │
        ▼
   NGINX (terminaison TLS, injection d'en-têtes SSO)
        │  X-Remote-User: <ldap_uid>
        │  X-Remote-Email: <email>
        │  Upgrade: websocket
        ▼
   Passerelle OpenClaw (127.0.0.1:18789)
        │
        ├── ~/.openclaw/openclaw.json     (configuration runtime)
        ├── ~/.openclaw/credentials/      (jetons des canaux)
        ├── ~/.openclaw/agents/           (état des agents)
        └── ~/.openclaw/workspace/        (compétences, mémoires)
```

## Documentation et ressources

- **Documentation upstream** : https://docs.openclaw.ai
- **Site web upstream** : https://openclaw.ai
- **Code upstream** : https://github.com/openclaw/openclaw
- **Documentation d'empaquetage YunoHost** : https://doc.yunohost.org/dev/packaging/
- **Signaler un bug** : https://github.com/MRsuffixx/OpenClaw_ynh/issues

## Contribution

Veuillez envoyer les pull requests sur la branche `testing`.

Pour tester la branche de développement :

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Version distribuée

**Version OpenClaw** : 1.0~ynh1

---

*Plus d'informations concernant l'empaquetage d'applications :* https://doc.yunohost.org/dev/packaging/