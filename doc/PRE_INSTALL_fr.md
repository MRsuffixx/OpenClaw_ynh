# Avant d'installer OpenClaw

## Prérequis

Avant d'installer OpenClaw, assurez-vous que votre serveur YunoHost répond aux exigences suivantes :

- **Version de YunoHost** : 11.2 ou ultérieure
- **Architecture** : `amd64` ou `arm64` (Raspberry Pi 4/5 pris en charge ; ARM 32 bits non pris en charge)
- **Espace disque** : Au moins 1 Go pour Node.js, le paquet OpenClaw et l'espace de travail
- **RAM** : 512 Mo pour la compilation, 256 Mo pour l'exécution

## Notes importantes

- OpenClaw se lie exclusivement à `127.0.0.1:18789` — il n'est jamais exposé directement à Internet
- La passerelle est accessible via NGINX avec terminaison TLS et passage SSO
- L'installation se fait via le script officiel `install-cli.sh` qui provisionne son propre environnement Node.js
- Le répertoire de données (`/home/openclaw/.openclaw/`) est conservé lors de la suppression ; utilisez `--purge` pour supprimer toutes les données

## Liste de contrôle pré-installation

- [ ] YunoHost 11.2+ est installé et fonctionnel
- [ ] Le domaine est configuré dans YunoHost
- [ ] Le DNS est correctement configuré pour votre domaine
- [ ] Aucune autre application n'utilise le port 18789 (ou laissez YunoHost auto-assigner un port)
- [ ] Vous avez un accès admin à YunoHost