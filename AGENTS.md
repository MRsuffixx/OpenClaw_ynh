# AGENTS.md — OpenClaw YunoHost Package
## `github.com/MRsuffixx/OpenClaw_ynh`

> **Purpose of this file:** Comprehensive agent/contributor guide for building, maintaining, and extending the YunoHost package for [OpenClaw](https://openclaw.ai). Read this before touching any script.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Architecture & How It All Fits Together](#3-architecture--how-it-all-fits-together)
4. [Prerequisites & Dependencies](#4-prerequisites--dependencies)
5. [manifest.toml — Full Specification](#5-manifesttoml--full-specification)
6. [Script-by-Script Breakdown](#6-script-by-script-breakdown)
   - [install](#61-install)
   - [upgrade](#62-upgrade)
   - [remove](#63-remove)
   - [backup](#64-backup)
   - [restore](#65-restore)
   - [change_url](#66-change_url)
   - [config](#67-config)
   - [\_common.sh](#68-_commonsh)
7. [LDAP & SSO Integration](#7-ldap--sso-integration)
8. [NGINX Configuration](#8-nginx-configuration)
9. [Systemd Service Design](#9-systemd-service-design)
10. [Node.js & OpenClaw Installation Strategy](#10-nodejs--openclaw-installation-strategy)
11. [Gateway Lifecycle Management](#11-gateway-lifecycle-management)
12. [Configuration Panel (config_panel.toml)](#12-configuration-panel-config_paneltoml)
13. [Permissions & ACL Model](#13-permissions--acl-model)
14. [Backup & Restore Strategy](#14-backup--restore-strategy)
15. [Upgrade Strategy](#15-upgrade-strategy)
16. [Update Channel Management](#16-update-channel-management)
17. [Fail2Ban Integration](#17-fail2ban-integration)
18. [Logrotate Configuration](#18-logrotate-configuration)
19. [Multi-Instance Support](#19-multi-instance-support)
20. [ARM / Raspberry Pi Support](#20-arm--raspberry-pi-support)
21. [Testing Checklist](#21-testing-checklist)
22. [Known Limitations & TODOs](#22-known-limitations--todos)
23. [Contribution Workflow](#23-contribution-workflow)
24. [Reference: Key File Paths](#24-reference-key-file-paths)

---

## 1. Project Overview

OpenClaw is an AI gateway and agentic runtime that exposes a WebSocket/HTTP Gateway on `127.0.0.1:18789` (default). This YunoHost package:

- Installs OpenClaw using its **official `install-cli.sh`** (npm method, pinned Node 22 LTS) into a dedicated system user's home.
- Registers and manages a **systemd user service** (`openclaw-gateway.service`) with lingering enabled, so the gateway survives user logouts.
- Configures **NGINX** as a reverse proxy with WebSocket upgrade support, TLS termination, and optional subpath routing.
- Integrates with **YunoHost LDAP / SSO** via HTTP header injection (Authelia/SSOwat passthrough) since OpenClaw itself does not natively speak LDAP; the package bridges this via a thin authentication shim in the NGINX layer.
- Provides a **YunoHost config panel** (`/yunohost/admin`) for managing gateway settings, update channels, and auth tokens without touching config files by hand.
- Fully supports **backup, restore, upgrade, remove, change_url**, and **multi-instance** deployments.

OpenClaw state lives in `~openclaw/.openclaw/` (i.e., `$data_dir`). The npm/Node toolchain lives in `~openclaw/.openclaw/tools/`. Application data and credentials are kept strictly separate from the package code so upgrades cannot corrupt user state.

---

## 2. Repository Structure

```
OpenClaw_ynh/
├── manifest.toml               # App metadata, resources, arguments, permissions
├── AGENTS.md                   # This file
├── README.md                   # Auto-generated (do not edit by hand)
├── README_fr.md                # Auto-generated French readme
├── LICENSE                     # AGPL-3.0 (package license, not OpenClaw's license)
│
├── scripts/
│   ├── _common.sh              # Shared variables, helper functions, version pins
│   ├── install                 # Fresh install script
│   ├── upgrade                 # Upgrade script
│   ├── remove                  # Removal script
│   ├── backup                  # Backup declarations
│   ├── restore                 # Restore script
│   ├── change_url              # Domain/path migration script
│   └── config                  # Config panel getter/setter logic
│
├── conf/
│   ├── nginx.conf              # NGINX reverse proxy template
│   ├── systemd.service         # Systemd unit template (system-level managed by YunoHost)
│   ├── openclaw.json           # OpenClaw gateway config template (~/.openclaw/openclaw.json)
│   ├── extra_php-fpm.conf      # NOT USED — OpenClaw is Node-based; keep empty or remove
│   ├── fail2ban_jail.conf      # Fail2Ban jail definition
│   ├── fail2ban_filter.conf    # Fail2Ban log filter regex for auth failures
│   └── logrotate               # Logrotate config for /var/log/openclaw/
│
├── doc/
│   ├── screenshots/            # At least one screenshot for the app catalog
│   ├── DESCRIPTION.md          # Long description (English)
│   ├── DESCRIPTION_fr.md       # Long description (French)
│   └── ADMIN.md                # Post-install admin notes
│
└── tests/
    └── tests.toml              # YunoHost CI/CD test matrix
```

---

## 3. Architecture & How It All Fits Together

```
Browser / YunoHost SSO (SSOwat)
        │
        ▼
   NGINX (TLS termination, SSO header injection)
        │  X-Remote-User: <ldap_uid>
        │  X-Remote-Email: <email>
        │  Upgrade: websocket  ◄── WebSocket passthrough for live gateway comms
        ▼
   OpenClaw Gateway  (127.0.0.1:18789)
        │
        ├── ~/.openclaw/openclaw.json     (runtime config)
        ├── ~/.openclaw/credentials/      (channel tokens, e.g. Telegram, Discord)
        ├── ~/.openclaw/agents/           (agent state, sessions)
        ├── ~/.openclaw/workspace/        (skills, prompts, memories)
        └── ~/.openclaw/tools/            (Node.js + npm, isolated)
```

**Key design decisions:**

- OpenClaw runs as a **dedicated system user** (`openclaw` or `__APP__` in YunoHost notation) to enforce filesystem isolation.
- The Gateway binds only to `127.0.0.1:18789` — it is **never exposed directly** to the internet.
- NGINX handles all external traffic, WebSocket upgrades, and SSO token injection.
- Lingering (`loginctl enable-linger`) ensures the systemd **user** service stays alive without an active login session.
- Because OpenClaw does not natively authenticate via LDAP, SSO is implemented as **header-based authentication**: NGINX passes `X-Remote-User` headers after SSOwat validates the YunoHost session cookie. OpenClaw's `gateway.auth.headerUser` option reads this header.

---

## 4. Prerequisites & Dependencies

### System packages (installed automatically by YunoHost manifest `apt` resource)

| Package | Why |
|---|---|
| `nodejs` | Runtime — but **do not use the distro nodejs**; see §10 |
| `npm` | Bootstrap only; OpenClaw bundles its own Node via `install-cli.sh` |
| `git` | Required by `install-cli.sh` even for npm installs |
| `curl` | Used by `install-cli.sh` for downloads |
| `ca-certificates` | TLS verification during install |
| `build-essential` | Native addon compilation (sharp, sqlite3, etc.) |
| `python3` | node-gyp dependency |

> **Important:** The package uses `install-cli.sh`'s self-contained Node (`~/.openclaw/tools/node/`). The system `nodejs` is only needed as a bootstrap. After install, `PATH` is adjusted so the gateway uses OpenClaw's own Node binary.

### YunoHost minimum version

`>= 11.2` (for `ynh_app_setting_set_default` and v2.1 manifest helpers)

### Architecture support

`amd64`, `arm64` (Raspberry Pi 4/5, Oracle Cloud ARM). 32-bit ARM (`armhf`) is **not supported** — OpenClaw's bundled Node does not ship `armv7l` binaries.

---

## 5. manifest.toml — Full Specification

```toml
packaging_format = 2
id = "openclaw"
name = "OpenClaw"
description.en = "Self-hosted AI gateway and agentic runtime with multi-channel messaging support"
description.fr = "Passerelle IA auto-hébergée avec support multi-canaux et agents autonomes"

version = "1.0~ynh1"

maintainers = ["MRsuffixx"]

[upstream]
license = "AGPL-3.0"
website = "https://openclaw.ai"
admindoc = "https://docs.openclaw.ai"
userdoc = "https://docs.openclaw.ai"
code = "https://github.com/openclaw/openclaw"

[integration]
yunohost = ">= 11.2"
helpers_version = "2.1"
architectures = ["amd64", "arm64"]
multi_instance = true
ldap = "not_relevant"   # SSO handled via NGINX header injection; see §7
sso = true
disk = "1G"              # Node + OpenClaw npm package + workspace
ram.build = "512M"
ram.runtime = "256M"

[install]

  [install.domain]
  type = "domain"

  [install.path]
  type = "path"
  default = "/"

  [install.init_main_permission]
  type = "group"
  default = "admins"

  [install.openclaw_version]
  ask.en = "OpenClaw version to install (leave 'latest' for stable release)"
  type = "string"
  default = "latest"

  [install.update_channel]
  ask.en = "Update channel"
  type = "select"
  choices = ["stable", "beta", "dev"]
  default = "stable"

  [install.gateway_auth_token]
  ask.en = "Gateway auth token (leave empty to auto-generate)"
  type = "string"
  default = ""
  optional = true

  [install.auto_update]
  ask.en = "Enable automatic updates?"
  type = "boolean"
  default = false

[resources]

  [resources.sources.main]
  # No upstream tarball — installation is done via install-cli.sh at runtime
  # This resource is intentionally left minimal; actual download happens in the install script
  autoupdate.strategy = "none"

  [resources.system_user]
  # Creates the 'openclaw' (or openclaw__N for multi-instance) system user
  # home_dir is set to data_dir so OpenClaw's ~/.openclaw resolves correctly
  home_dir = "/home/__APP__"
  allow_email = false

  [resources.install_dir]
  # Stores the package scripts and conf — NOT the OpenClaw state
  dir = "/opt/yunohost/__APP__"
  owner = "__APP__:__APP__"
  group = "www-data:r-x"

  [resources.data_dir]
  # OpenClaw state: ~/.openclaw equivalent — credentials, agents, workspace
  dir = "/home/__APP__/.openclaw"
  owner = "__APP__:__APP__"

  [resources.ports]
  main.default = 18789
  # Port is bound to 127.0.0.1 only — never exposed to the internet

  [resources.apt]
  packages = ["git", "curl", "ca-certificates", "build-essential", "python3"]
  # nodejs intentionally excluded — OpenClaw self-provisions Node via install-cli.sh

  [resources.permissions]
  main.url = "/"
  main.label = "OpenClaw"
  main.allowed = "admins"
  main.auth_header = true    # Enables SSOwat to inject X-Remote-User header
  api.url = "/api"
  api.label = "OpenClaw API"
  api.allowed = "visitors"   # API may be accessed by configured bots/channels
  api.show_tile = false
  api.protected = true
```

---

## 6. Script-by-Script Breakdown

### 6.1 `install`

**Flow:**

1. **Provision system user** — YunoHost creates `$app` user with home at `/home/$app`. `loginctl enable-linger $app` is called so the user's systemd instance persists after logout.

2. **Write HOME override** — OpenClaw reads `$HOME` to locate `~/.openclaw`. Because the script runs as root, we must explicitly export `HOME=/home/$app` before calling any `openclaw` or `install-cli.sh` commands.

3. **Run `install-cli.sh`** — Downloaded with integrity verification (SHA256 pinned in `_common.sh`). Invoked with:
   ```bash
   sudo -u "$app" env \
     HOME="/home/$app" \
     OPENCLAW_PREFIX="/home/$app/.openclaw" \
     OPENCLAW_VERSION="$openclaw_version" \
     OPENCLAW_INSTALL_METHOD="npm" \
     SHARP_IGNORE_GLOBAL_LIBVIPS=1 \
     bash /tmp/install-cli.sh --no-onboard --json
   ```
   The `--no-onboard` flag skips interactive prompts. `--json` produces machine-parseable output for logging.

4. **Write `openclaw.json`** — Template at `conf/openclaw.json` is rendered via `ynh_config_add` with substitutions for `$port`, `$domain`, `$gateway_auth_token`, `$app`, `$update_channel`.

5. **Configure PATH** — A profile drop-in at `/etc/profile.d/openclaw_$app.sh` adds `/home/$app/.openclaw/bin` to `PATH` for admin convenience. This is **not** required for the service (systemd unit sets `PATH` explicitly).

6. **Install systemd unit** — `ynh_config_add_systemd` renders `conf/systemd.service`. The unit runs as `User=$app`, sets correct `HOME`, `OPENCLAW_NO_RESPAWN=1`, and `NODE_COMPILE_CACHE`.

7. **Enable lingering** — `loginctl enable-linger "$app"` ensures the user's systemd instance stays alive.

8. **Configure NGINX** — `ynh_config_add_nginx` renders `conf/nginx.conf` with WebSocket upgrade headers and SSO auth header passthrough.

9. **Set permissions** — `yunohost app addaccess --users all "$app"` or restricted per `$init_main_permission`.

10. **Register service** — `yunohost service add "$app"` with health test command.

11. **Configure Fail2Ban** — `ynh_config_add_fail2ban` targeting OpenClaw gateway logs.

12. **Start service** — `ynh_systemctl --service="$app" --action="start"`.

13. **Post-install doctor** — Run `sudo -u "$app" "$OPENCLAW_BIN" doctor --non-interactive` and log output.

**Critical variables set in install:**
```bash
export OPENCLAW_BIN="/home/$app/.openclaw/bin/openclaw"
export OPENCLAW_STATE_DIR="/home/$app/.openclaw"
export NODE_BIN="/home/$app/.openclaw/tools/node/bin/node"
```

---

### 6.2 `upgrade`

**Flow:**

1. Stop the gateway service.
2. `ynh_app_setting_set_default` for any new settings introduced since last version.
3. Re-render all config files via `ynh_config_add` (config, nginx, systemd, logrotate, fail2ban).
4. Run `openclaw update` (or re-run `install-cli.sh` if update fails):
   ```bash
   sudo -u "$app" env HOME="/home/$app" "$OPENCLAW_BIN" update \
     --channel "$update_channel" --yes --non-interactive --json \
     || curl -fsSL https://openclaw.ai/install.sh | \
        sudo -u "$app" env HOME="/home/$app" bash -s -- \
        --install-method npm --no-onboard --json
   ```
5. Run `openclaw doctor --fix --non-interactive`.
6. Re-register service via `yunohost service add` (to pick up new flags).
7. Restart gateway, verify with `openclaw health`.

**Version migration hooks:**

For each major bump, add a function in `_common.sh`:
```bash
ynh_upgrade_from_v1_to_v2() {
    # e.g., rename a setting key, migrate a config field
    ynh_app_setting_set_default --key=update_channel --value="stable"
}
```
Call it inside `upgrade` wrapped in a version guard:
```bash
if ynh_compare_current_package_version --comparison lt --version "2.0~ynh1"; then
    ynh_upgrade_from_v1_to_v2
fi
```

---

### 6.3 `remove`

**Flow:**

1. Stop and disable the gateway service:
   ```bash
   ynh_systemctl --service="$app" --action="stop"
   ```
2. Run OpenClaw's own uninstaller to cleanly deregister the service unit:
   ```bash
   sudo -u "$app" env HOME="/home/$app" "$OPENCLAW_BIN" \
       uninstall --all --yes --non-interactive 2>/dev/null || true
   ```
3. Disable lingering:
   ```bash
   loginctl disable-linger "$app" 2>/dev/null || true
   ```
4. Remove profile drop-in:
   ```bash
   ynh_safe_rm "/etc/profile.d/openclaw_${app}.sh"
   ```
5. Remove YunoHost service registration, systemd unit, NGINX config, logrotate, fail2ban via standard helpers.
6. YunoHost core removes `$install_dir`, `$data_dir` (only if `--purge`), and the system user.

> **Note:** `$data_dir` (`/home/$app/.openclaw`) contains credentials and workspace. It is **retained by default** on removal. Only `--purge` deletes it. Document this clearly in `doc/ADMIN.md`.

---

### 6.4 `backup`

Declarations only (no actual file copies here — YunoHost core does the copying):

```bash
ynh_backup "$install_dir"
ynh_backup "$data_dir"
ynh_backup "/etc/nginx/conf.d/$domain.d/$app.conf"
ynh_backup "/etc/systemd/system/$app.service"
ynh_backup "/etc/logrotate.d/$app"
ynh_backup "/etc/fail2ban/jail.d/$app.conf"
ynh_backup "/etc/fail2ban/filter.d/$app.conf"
ynh_backup "/etc/profile.d/openclaw_${app}.sh"
ynh_backup "/var/log/$app/"
```

> `$data_dir` is **not** backed up during safety-backup-before-upgrade (YunoHost default behavior) because it may be large (workspace + sessions). It **is** included in manual `yunohost backup create` runs.

---

### 6.5 `restore`

**Flow:**

1. Restore all declared paths via `ynh_restore`.
2. Re-create system user with correct home if it doesn't exist (YunoHost provisioning handles this).
3. Re-enable lingering: `loginctl enable-linger "$app"`.
4. `chown -R "$app:$app" "$data_dir"` and `chown -R "$app:www-data" "$install_dir"`.
5. Re-enable and reload systemd unit.
6. Re-register service with `yunohost service add`.
7. Reload fail2ban, reload nginx, start the app service.
8. Run `openclaw doctor` to validate restored state.

---

### 6.6 `change_url`

**Flow:**

1. Stop the gateway service.
2. `ynh_config_change_url_nginx` — automatically adjusts the NGINX config for the new domain/path.
3. Update `$domain` and `$path` in `openclaw.json` if OpenClaw's config references the external URL:
   ```bash
   ynh_app_setting_set --key=domain --value="$new_domain"
   ynh_app_setting_set --key=path --value="$new_path"
   ynh_config_add --template="openclaw.json" \
       --destination="$data_dir/openclaw.json"
   ```
4. Restart gateway.

---

### 6.7 `config`

The config script handles the YunoHost admin panel (`config_panel.toml`). Key getters/setters:

**`get__update_channel`** — reads `update.channel` from `openclaw.json` via `jq`.

**`set__update_channel`** — writes the value into `openclaw.json` and saves to YunoHost settings.

**`get__gateway_auth_token`** — reads `gateway.auth.token` from `openclaw.json`. Returns `YNH_NULL` if unset (so the panel shows the placeholder).

**`set__gateway_auth_token`** — writes the token, then restarts the gateway service.

**`get__openclaw_version`** — runs `"$OPENCLAW_BIN" --version 2>/dev/null | head -n1` to show the currently installed version (read-only display field).

**`validate__gateway_auth_token`** — enforces minimum 16-character length:
```bash
validate__gateway_auth_token() {
    [[ ${#gateway_auth_token} -ge 16 ]] || echo "Token must be at least 16 characters."
}
```

---

### 6.8 `_common.sh`

Centralizes all shared state to avoid duplication. Must define:

```bash
# Pinned installer SHA256 (update on each package release)
INSTALL_CLI_SHA256="<sha256 of install-cli.sh at time of package release>"
INSTALL_CLI_URL="https://openclaw.ai/install-cli.sh"

# Path shortcuts (set after provisioning, not at source-time)
openclaw_bin() { echo "/home/${app}/.openclaw/bin/openclaw"; }
openclaw_state_dir() { echo "/home/${app}/.openclaw"; }
node_bin() { echo "/home/${app}/.openclaw/tools/node/bin/node"; }

# Run openclaw as the app user with correct HOME
run_as_openclaw() {
    sudo -u "$app" \
        env HOME="/home/$app" \
            OPENCLAW_STATE_DIR="/home/$app/.openclaw" \
            OPENCLAW_NO_RESPAWN=1 \
            NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache-${app}" \
        "$@"
}

# Download with SHA256 verification
download_verified() {
    local url="$1" dest="$2" expected_sha="$3"
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 -o "$dest" "$url"
    local actual_sha
    actual_sha="$(sha256sum "$dest" | awk '{print $1}')"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        ynh_die "SHA256 mismatch for $url: expected $expected_sha, got $actual_sha"
    fi
}
```

---

## 7. LDAP & SSO Integration

OpenClaw does not natively authenticate against LDAP. The YunoHost integration uses a **header-based SSO bridge**:

### How it works

1. **SSOwat** (YunoHost's SSO layer) intercepts requests at the NGINX level.
2. After validating the YunoHost session cookie, SSOwat injects headers:
   - `X-Remote-User: <uid>` — the YunoHost username
   - `X-Remote-Email: <email>` — from LDAP
   - `X-Remote-Fullname: <cn>` — display name
3. The NGINX reverse proxy passes these headers to the OpenClaw Gateway.
4. OpenClaw is configured with:
   ```json
   {
     "gateway": {
       "auth": {
         "headerUser": "X-Remote-User",
         "headerEmail": "X-Remote-Email"
       }
     }
   }
   ```
5. The gateway trusts these headers **only from 127.0.0.1** (loopback). External direct access to `:18789` is blocked by firewall/binding.

### manifest.toml flags

```toml
[integration]
ldap = "not_relevant"   # OpenClaw doesn't speak LDAP directly
sso = true              # SSOwat integration is active
```

```toml
[resources.permissions]
main.auth_header = true   # Tells SSOwat to inject auth headers for this app
```

### Security notes

- **Never** bind the gateway to `0.0.0.0` — keep it on `127.0.0.1:$port`.
- The `gateway.auth.token` provides a secondary shared-secret layer for API clients that bypass NGINX (e.g., local CLI).
- For multi-user setups, each YunoHost user gets their own OpenClaw identity via the injected `X-Remote-User` header. Gateway-level per-user isolation depends on OpenClaw's agent/session model.

---

## 8. NGINX Configuration

**File:** `conf/nginx.conf`

```nginx
location __PATH__/ {
    proxy_pass http://127.0.0.1:__PORT__/;
    proxy_http_version 1.1;

    # WebSocket support (required for OpenClaw Gateway WS)
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;

    # SSO header passthrough
    proxy_set_header X-Remote-User    $http_x_remote_user;
    proxy_set_header X-Remote-Email   $http_x_remote_email;
    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host             $host;

    # Strip the subpath prefix if OpenClaw is not mounted at /
    rewrite ^__PATH__/(.*)$ /$1 break;

    more_clear_input_headers 'Authorization';
    include conf.d/yunohost_panel.conf.inc;
}

# Dedicated WebSocket endpoint (some clients connect directly)
location __PATH__/ws {
    proxy_pass http://127.0.0.1:__PORT__/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400s;
}
```

**Key points:**
- `proxy_read_timeout 86400s` — long-lived WebSocket connections must not be killed by NGINX's default 60s timeout.
- `more_clear_input_headers 'Authorization'` — prevents clients from injecting their own auth headers that could bypass SSO.
- The `rewrite` rule strips the YunoHost subpath so OpenClaw always sees requests at `/`.

---

## 9. Systemd Service Design

**File:** `conf/systemd.service`

```ini
[Unit]
Description=OpenClaw Gateway (__APP__)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=__APP__
Group=__APP__
WorkingDirectory=/home/__APP__/.openclaw
Environment=HOME=/home/__APP__
Environment=OPENCLAW_STATE_DIR=/home/__APP__/.openclaw
Environment=OPENCLAW_NO_RESPAWN=1
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache-__APP__
Environment=PATH=/home/__APP__/.openclaw/bin:/home/__APP__/.openclaw/tools/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=/bin/mkdir -p /var/tmp/openclaw-compile-cache-__APP__
ExecStart=/home/__APP__/.openclaw/bin/openclaw gateway --port __PORT__
ExecStop=/home/__APP__/.openclaw/bin/openclaw gateway stop
Restart=always
RestartSec=2
TimeoutStartSec=90
TimeoutStopSec=30
StandardOutput=append:/var/log/__APP__/__APP__.log
StandardError=append:/var/log/__APP__/error.log

[Install]
WantedBy=multi-user.target
```

**Design rationale:**
- `OPENCLAW_NO_RESPAWN=1` — prevents OpenClaw's internal respawn logic from conflicting with systemd's `Restart=always`.
- `NODE_COMPILE_CACHE` — per-instance cache path avoids conflicts in multi-instance setups and speeds up cold starts on ARM/low-power hosts.
- `ExecStartPre` creates the compile cache directory if absent.
- `Type=simple` works with `OPENCLAW_NO_RESPAWN=1`; if respawn is re-enabled, switch to `Type=forking` with a `PIDFile`.
- Logs go to `/var/log/$app/` managed by logrotate.

**Creating the log directory in `install`:**
```bash
mkdir -p "/var/log/$app"
chown "$app:$app" "/var/log/$app"
```

---

## 10. Node.js & OpenClaw Installation Strategy

OpenClaw's `install-cli.sh` downloads and manages its **own Node.js** under `~/.openclaw/tools/node/`. This is intentional and must be respected:

- Do **not** install `nodejs` from apt and use it as the runtime.
- Do **not** run `npm install -g openclaw` as root — always run as `$app` user.
- The install script pins Node 22.22.0 LTS by default (`OPENCLAW_NODE_VERSION`). This pin lives in `_common.sh` and must be updated when OpenClaw drops support for older Node.

### Install procedure in detail

```bash
# 1. Download install-cli.sh with integrity check
download_verified \
    "$INSTALL_CLI_URL" \
    /tmp/openclaw_install_cli_$$.sh \
    "$INSTALL_CLI_SHA256"
chmod +x /tmp/openclaw_install_cli_$$.sh

# 2. Run as app user
run_as_openclaw bash /tmp/openclaw_install_cli_$$.sh \
    --no-onboard \
    --install-method npm \
    --version "$openclaw_version" \
    --prefix "/home/$app/.openclaw" \
    --set-npm-prefix \
    --json 2>&1 | tee -a /var/log/$app/install.log

# 3. Cleanup
rm -f /tmp/openclaw_install_cli_$$.sh
```

### Handling install-cli.sh SHA256 updates

When releasing a new package version that bundles a newer `install-cli.sh`:
1. Download the new installer.
2. Compute: `sha256sum install-cli.sh`
3. Update `INSTALL_CLI_SHA256` in `_common.sh`.
4. Bump `version` in `manifest.toml`.

---

## 11. Gateway Lifecycle Management

### Start / stop wrappers

Always use the YunoHost helper when possible:
```bash
ynh_systemctl --service="$app" --action="start"
ynh_systemctl --service="$app" --action="stop"
ynh_systemctl --service="$app" --action="restart"
```

### Health check

After start, poll the readiness endpoint:
```bash
wait_for_gateway() {
    local max_attempts=30
    local attempt=0
    local port="$1"
    while ! curl -fsS "http://127.0.0.1:${port}/readyz" >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $max_attempts ]]; then
            ynh_print_warn "OpenClaw gateway did not become ready in time"
            return 1
        fi
        sleep 2
    done
    ynh_print_info "OpenClaw gateway is ready."
}
```

### Registering the service with YunoHost

```bash
yunohost service add "$app" \
    --description="OpenClaw AI Gateway" \
    --log="/var/log/$app/$app.log" \
    --test_status="curl -fsS http://127.0.0.1:${port}/readyz"
```

The `--test_status` command is used by YunoHost's diagnosis system to report whether the service is healthy.

---

## 12. Configuration Panel (config_panel.toml)

**File:** `conf/config_panel.toml` *(create this file)*

```toml
version = "1.0"

[main]
name = "OpenClaw Settings"

    [main.gateway]
    name = "Gateway"

        [main.gateway.update_channel]
        ask.en = "Update channel"
        type = "select"
        choices = ["stable", "beta", "dev"]
        bind = "yaml:__DATA_DIR__/openclaw.json:update.channel"

        [main.gateway.auto_update]
        ask.en = "Enable automatic updates"
        type = "boolean"
        bind = "yaml:__DATA_DIR__/openclaw.json:update.auto.enabled"

        [main.gateway.gateway_auth_token]
        ask.en = "Gateway auth token (shared secret for API access)"
        type = "string"
        bind = "yaml:__DATA_DIR__/openclaw.json:gateway.auth.token"
        redact = true

    [main.info]
    name = "Info (read-only)"

        [main.info.openclaw_version]
        ask.en = "Installed OpenClaw version"
        type = "display"

        [main.info.gateway_status]
        ask.en = "Gateway status"
        type = "display"
```

The `config` script's `get__openclaw_version` and `get__gateway_status` populate the display fields dynamically at panel load time.

---

## 13. Permissions & ACL Model

| Permission | Default Group | Description |
|---|---|---|
| `main` | `admins` | Access to the OpenClaw web UI |
| `api` | `visitors` | Access to `/api` for bot/channel integrations |

Permissions are enforced by SSOwat at the NGINX layer. The `api` permission is intentionally open to `visitors` because Telegram/Discord bots call the API without a browser session; they authenticate via the `gateway.auth.token` header instead.

To restrict API access after install:
```bash
yunohost app changeaccess openclaw --permission api --remove visitors --add admins
```

---

## 14. Backup & Restore Strategy

### What is backed up

| Path | Contains | Backed up by default | Notes |
|---|---|---|---|
| `$install_dir` | Package scripts & conf | Yes | Small |
| `$data_dir` | OpenClaw state, credentials, workspace, agents | Yes (manual backup) | Can be large; excluded from upgrade safety backup |
| NGINX conf | Reverse proxy config | Yes | |
| Systemd unit | Service definition | Yes | |
| Logrotate conf | Log rotation rules | Yes | |
| Fail2Ban conf | Jail + filter | Yes | |
| `/var/log/$app/` | Application logs | Yes | Excluded from upgrade safety backup |

### Restore caveats

- After restore to a **new machine**, `loginctl enable-linger "$app"` must be re-run (handled in `restore` script).
- OpenClaw credential tokens (Telegram bot tokens, Discord tokens) are stored in `$data_dir/credentials/` and are restored with the data dir. No re-pairing is needed if the backup is complete.
- If the Node binary path changed between versions, run `openclaw doctor --fix` after restore.

---

## 15. Upgrade Strategy

### Upgrade matrix

| From | To | Action |
|---|---|---|
| 1.x~ynh1 | 1.x~ynh2+ | Re-render configs, run `openclaw update`, restart |
| 1.x | 2.x | Run migration hook, full re-install of OpenClaw if major bump |
| Any | Any (npm→git) | Not supported via `upgrade`; use `openclaw update --channel dev` manually |

### Safe upgrade procedure (from the install script perspective)

```bash
# Stop service
ynh_systemctl --service="$app" --action="stop"

# Update OpenClaw itself
if run_as_openclaw "$(openclaw_bin)" update \
        --channel "$update_channel" --yes --non-interactive --json; then
    ynh_print_info "OpenClaw updated successfully via openclaw update"
else
    ynh_print_warn "openclaw update failed; falling back to install-cli.sh"
    download_verified "$INSTALL_CLI_URL" /tmp/openclaw_install_$$.sh "$INSTALL_CLI_SHA256"
    run_as_openclaw bash /tmp/openclaw_install_$$.sh \
        --install-method npm --no-onboard --json
    rm -f /tmp/openclaw_install_$$.sh
fi

# Re-run doctor to fix any post-update issues
run_as_openclaw "$(openclaw_bin)" doctor --fix --non-interactive 2>&1 \
    | tee -a /var/log/$app/upgrade.log

# Re-apply all YunoHost-managed configs
ynh_config_add --template="openclaw.json" \
    --destination="$data_dir/openclaw.json"
ynh_config_add_systemd
ynh_config_add_nginx
ynh_config_add_logrotate
ynh_config_add_fail2ban --logpath="/var/log/$app/error.log" \
    --failregex="__FAILREGEX__"

# Restart
ynh_systemctl --service="$app" --action="start"
```

---

## 16. Update Channel Management

OpenClaw supports three channels: `stable`, `beta`, `dev`.

- `stable` — recommended for production; uses npm published releases.
- `beta` — early access; falls back to stable if no beta tag is newer.
- `dev` — git checkout; **not supported** by this YunoHost package (requires `pnpm` and build tooling not available on typical YunoHost servers). Selecting `dev` in the config panel should display a warning and be blocked.

The channel is stored in:
- YunoHost setting: `ynh_app_setting_get --key=update_channel`
- OpenClaw config: `~/.openclaw/openclaw.json` → `update.channel`

Both must be kept in sync. The `config` script's `set__update_channel` setter writes to both.

Auto-update config written to `openclaw.json`:
```json
{
  "update": {
    "channel": "__UPDATE_CHANNEL__",
    "checkOnStart": true,
    "auto": {
      "enabled": __AUTO_UPDATE__,
      "stableDelayHours": 6,
      "stableJitterHours": 12,
      "betaCheckIntervalHours": 1
    }
  }
}
```

---

## 17. Fail2Ban Integration

**File:** `conf/fail2ban_filter.conf`

```ini
[Definition]
failregex = .*\[openclaw\].*auth.*failed.*from <HOST>
            .*\[openclaw\].*invalid token.*from <HOST>
            .*\[openclaw\].*unauthorized.*<HOST>
ignoreregex =
```

**File:** `conf/fail2ban_jail.conf`

```ini
[openclaw]
enabled  = true
port     = http,https
filter   = openclaw
logpath  = /var/log/__APP__/error.log
maxretry = 5
bantime  = 600
findtime = 300
```

Update the `failregex` patterns once OpenClaw's actual log format for auth failures is confirmed. Check `~/.openclaw/` logs or `/var/log/$app/error.log` after a deliberate failed auth attempt.

---

## 18. Logrotate Configuration

**File:** `conf/logrotate`

```
/var/log/__APP__/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 __APP__ www-data
    sharedscripts
    postrotate
        systemctl kill -s USR1 __APP__.service 2>/dev/null || true
    endscript
}
```

`USR1` is the conventional signal for log rotation notification in many Node.js apps. Verify OpenClaw actually handles `USR1` for log re-opening; if not, use `postrotate: systemctl restart __APP__` with a `delaycompress` window.

---

## 19. Multi-Instance Support

`multi_instance = true` in `manifest.toml` means YunoHost will name instances `openclaw`, `openclaw__2`, `openclaw__3`, etc.

Each instance gets:
- Its own system user: `openclaw`, `openclaw__2`, …
- Its own port (auto-incremented by YunoHost's port resource).
- Its own state dir: `/home/openclaw__2/.openclaw/`.
- Its own systemd service: `openclaw__2.service`.
- Its own NGINX location block (different domain or path).
- Its own `NODE_COMPILE_CACHE` path to avoid cross-instance corruption.

No code changes are needed — the `__APP__` and `__PORT__` placeholders in templates handle this automatically. The only multi-instance footgun is the compile cache: always use `NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache-${app}` (not a fixed path).

---

## 20. ARM / Raspberry Pi Support

OpenClaw's bundled Node.js includes `arm64` binaries. `armhf` (32-bit) is **not supported**.

For ARM hosts, add startup tuning in `_common.sh` and propagate to the systemd unit:

```bash
# In _common.sh
arm_tuning_env() {
    local arch
    arch="$(uname -m)"
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        echo "OPENCLAW_NO_RESPAWN=1"
        echo "NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache-${app}"
    fi
}
```

The systemd template already includes both variables unconditionally, which is fine — they're beneficial on all architectures.

---

## 21. Testing Checklist

Before opening a PR to `main`, verify all of the following on a real or CI YunoHost instance:

### Installation
- [ ] Fresh install on a subdomain (`openclaw.example.com`)
- [ ] Fresh install on a subpath (`example.com/openclaw`)
- [ ] Install with `openclaw_version=latest` (default)
- [ ] Install with a pinned version (e.g. `openclaw_version=1.2.3`)
- [ ] `openclaw doctor` reports no errors after install
- [ ] `curl http://127.0.0.1:$port/readyz` returns 200
- [ ] Gateway is reachable via NGINX at the configured domain/path
- [ ] SSO login works (YunoHost user session is accepted)
- [ ] `X-Remote-User` header is correctly passed to the gateway

### Permissions
- [ ] `admins` group can access the UI
- [ ] Non-member users are redirected to SSO login
- [ ] API endpoint responds to requests with valid `gateway.auth.token`

### Backup & Restore
- [ ] `yunohost backup create --apps openclaw` completes without error
- [ ] `yunohost backup restore <archive> --apps openclaw` restores successfully
- [ ] Gateway starts and passes health check after restore
- [ ] Credentials/channels are intact after restore

### Upgrade
- [ ] `yunohost app upgrade openclaw` completes
- [ ] `openclaw --version` shows updated version
- [ ] Config files are not corrupted after upgrade
- [ ] User-modified `openclaw.json` settings survive upgrade (checksum-based backup)

### Removal
- [ ] `yunohost app remove openclaw` completes
- [ ] No leftover systemd services, NGINX configs, or Fail2Ban rules
- [ ] `/home/openclaw/.openclaw/` is retained (not purged)
- [ ] `yunohost app remove openclaw --purge` removes all data

### Multi-instance
- [ ] Second install (`openclaw__2`) on a different domain
- [ ] Both instances run independently on different ports
- [ ] Removing one instance does not affect the other

### ARM
- [ ] Install and health check on `arm64` (Raspberry Pi 4/5 or Oracle Cloud ARM)

---

## 22. Known Limitations & TODOs

- **No native LDAP auth** — OpenClaw's gateway does not speak LDAP. SSO is header-based. If OpenClaw adds native LDAP support in a future version, revisit `manifest.toml` `ldap` flag and implement proper LDAP config.
- **`dev` channel not supported** — Requires `pnpm` and full build toolchain. Blocked in the config panel.
- **`armhf` not supported** — OpenClaw does not ship 32-bit ARM Node binaries.
- **WebSocket reconnection** — If the gateway is restarted, browser clients need to reconnect. There is no automatic reconnect built into this package; the OpenClaw JS client handles it.
- **Large workspace backups** — `~/.openclaw/workspace/` can grow large if many skills/memories are stored. Consider documenting a `yunohost backup` size estimate in `doc/ADMIN.md`.
- **`openclaw update --channel dev`** on a running production instance will break the YunoHost-managed service unit. Document this as unsupported.
- **TODO:** Add `tests/tests.toml` with full CI matrix.
- **TODO:** Implement `get__gateway_status` in `config` script to show real-time gateway health in the YunoHost panel.
- **TODO:** Evaluate whether OpenClaw's `onboard` flow can be run non-interactively post-install to configure channels from YunoHost settings.

---

## 23. Contribution Workflow

1. Fork → branch off `testing`.
2. All changes go to `testing` first; `main` is for stable releases only.
3. Test with:
   ```bash
   sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
   sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
   ```
4. Run `shellcheck scripts/*` — all scripts must pass with no errors.
5. Update `AGENTS.md` if you change architecture, add new settings, or change file paths.
6. Bump `version` in `manifest.toml` on every release (format: `<upstream_version>~ynh<pkg_revision>`).
7. Open a PR to `testing`; after review and CI pass, merge to `main` and tag.

### Commit message format

```
feat(install): add NODE_COMPILE_CACHE for ARM performance
fix(nginx): correct websocket timeout header
docs(agents): update LDAP section with header injection details
chore(manifest): bump version to 1.2.3~ynh2
```

---

## 24. Reference: Key File Paths

| Path | Description |
|---|---|
| `/home/$app/.openclaw/` | OpenClaw state dir (`$data_dir`) |
| `/home/$app/.openclaw/bin/openclaw` | Main CLI binary |
| `/home/$app/.openclaw/tools/node/` | Isolated Node.js installation |
| `/home/$app/.openclaw/openclaw.json` | Runtime config |
| `/home/$app/.openclaw/credentials/` | Channel tokens (Telegram, Discord, etc.) |
| `/home/$app/.openclaw/agents/` | Agent state and sessions |
| `/home/$app/.openclaw/workspace/` | Skills, prompts, memories |
| `/opt/yunohost/$app/` | Package install dir (`$install_dir`) |
| `/etc/nginx/conf.d/$domain.d/$app.conf` | NGINX reverse proxy config |
| `/etc/systemd/system/$app.service` | Systemd service unit |
| `/etc/logrotate.d/$app` | Log rotation config |
| `/etc/fail2ban/jail.d/$app.conf` | Fail2Ban jail |
| `/etc/fail2ban/filter.d/$app.conf` | Fail2Ban filter |
| `/etc/profile.d/openclaw_$app.sh` | PATH drop-in for admin CLI use |
| `/var/log/$app/$app.log` | Gateway stdout log |
| `/var/log/$app/error.log` | Gateway stderr log |
| `/var/tmp/openclaw-compile-cache-$app/` | Node module compile cache |

---

*Last updated: May 2026 — MRsuffixx/OpenClaw_ynh*