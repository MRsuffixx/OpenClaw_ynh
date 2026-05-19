OpenClaw is a self-hosted AI gateway and agentic runtime that enables:

- **Multi-channel messaging**: Connect Telegram bots, Discord integrations, Slack, email, and other messaging platforms through a unified gateway
- **Agentic workflows**: Deploy AI agents that can reason, use tools, and execute tasks autonomously
- **WebSocket/HTTP gateway**: Expose a flexible API for external integrations with full bidirectional streaming support
- **YunoHost integration**: Runs as an isolated system user with SSO passthrough via your YunoHost authentication

The gateway runs locally on `127.0.0.1:18789` and is accessed exclusively through NGINX, which handles TLS termination and SSO header injection for seamless YunoHost user authentication.

## Key Features

| Feature | Description |
|---------|-------------|
| Multi-channel | Telegram, Discord, Slack, Email, and more |
| Agentic AI | Autonomous agents with tool use and reasoning |
| WebSocket streaming | Bidirectional real-time communication |
| SSO integration | Automatic YunoHost user authentication |
| Self-hosted | Full control over your data and infrastructure |
| Multi-instance | Run multiple independent instances on one server |