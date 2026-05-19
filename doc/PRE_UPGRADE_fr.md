# Avant de mettre à niveau OpenClaw

## Notes avant la mise à niveau

Avant de mettre à niveau OpenClaw, notez les points suivants :

- **Sauvegarde recommandée** : Exécutez `yunohost backup create --apps openclaw` avant la mise à niveau
- **Interruption du service** : La passerelle sera arrêtée pendant la mise à niveau
- **Répertoire de données préservé** : Le répertoire de données (`/home/__APP__/.openclaw/`) n'est PAS inclus dans les sauvegardes automatiques de sécurité
- **Modifications de configuration** : Les paramètres modifiés par l'utilisateur dans `openclaw.json` seront préservés si possible

## Processus de mise à niveau

1. Le script de mise à niveau arrête le service de la passerelle
2. Télécharge et exécute la nouvelle version d'OpenClaw via `openclaw update` ou `install-cli.sh`
3. Recrée tous les fichiers de configuration
4. Exécute `openclaw doctor --fix` pour réparer tout problème
5. Redémarre la passerelle et vérifie la santé

## Ce qui est préservé

- Identifiants des canaux dans `~/.openclaw/credentials/`
- État des agents dans `~/.openclaw/agents/`
- Données de l'espace de travail dans `~/.openclaw/workspace/`
- Paramètres `openclaw.json` modifiés par l'utilisateur (sauvegardés avant écrasement)

## Ce qui peut changer

- Structure de fichiers interne d'OpenClaw
- Valeurs par défaut dans `openclaw.json`
- Paramètres de l'unité de service systemd