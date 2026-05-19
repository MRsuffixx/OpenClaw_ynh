OpenClaw est une passerelle IA auto-hébergée et un runtime d'agents qui permet :

- **Messagerie multi-canaux** : Connectez des bots Telegram, des intégrations Discord, Slack, e-mail et d'autres plateformes de messagerie via une passerelle unifiée
- **Flux de travail agentiques** : Déployez des agents IA capables de raisonner, d'utiliser des outils et d'exécuter des tâches de manière autonome
- **Passerelle WebSocket/HTTP** : Exposez une API flexible pour les intégrations externes avec support de streaming bidirectionnel complet
- **Intégration YunoHost** : S'exécute en tant qu'utilisateur système isolé avec passage SSO via votre authentification YunoHost

La passerelle s'exécute localement sur `127.0.0.1:18789` et est accessible exclusivement via NGINX, qui gère la terminaison TLS et l'injection d'en-têtes SSO pour une authentification utilisateur YunoHost transparente.

## Fonctionnalités principales

| Fonctionnalité | Description |
|----------------|-------------|
| Multi-canaux | Telegram, Discord, Slack, E-mail et plus |
| IA agentique | Agents autonomes avec utilisation d'outils et raisonnement |
| Streaming WebSocket | Communication temps réel bidirectionnelle |
| Intégration SSO | Authentification automatique des utilisateurs YunoHost |
| Auto-hébergé | Contrôle total sur vos données et votre infrastructure |
| Multi-instances | Exécutez plusieurs instances indépendantes sur un seul serveur |