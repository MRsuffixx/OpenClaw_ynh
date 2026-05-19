#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

INSTALL_CLI_URL="https://openclaw.ai/install-cli.sh"
INSTALL_CLI_SHA256="0000000000000000000000000000000000000000000000000000000000000000"

openclaw_bin() {
    echo "/home/${app}/.openclaw/bin/openclaw"
}

openclaw_state_dir() {
    echo "/home/${app}/.openclaw"
}

node_bin() {
    echo "/home/${app}/.openclaw/tools/node/bin/node"
}

run_as_openclaw() {
    sudo -u "$app" \
        env HOME="/home/$app" \
            OPENCLAW_STATE_DIR="/home/$app/.openclaw" \
            OPENCLAW_NO_RESPAWN=1 \
            NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache-${app}" \
        "$@"
}

download_verified() {
    local url="$1" dest="$2" expected_sha="$3"
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 -o "$dest" "$url"
    local actual_sha
    actual_sha="$(sha256sum "$dest" | awk '{print $1}')"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        ynh_die "SHA256 mismatch for $url: expected $expected_sha, got $actual_sha"
    fi
}

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

ynh_upgrade_from_v1_to_v2() {
    ynh_app_setting_set_default --key=update_channel --value="stable"
}