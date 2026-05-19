#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

set -euo pipefail

#=================================================
# CONSTANTS
#=================================================
# NOTE: INSTALL_CLI_SHA256 must be updated whenever install-cli.sh changes.
# Run: curl -fsSL https://openclaw.ai/install-cli.sh | sha256sum
# Then update the value below.
INSTALL_CLI_URL="https://openclaw.ai/install-cli.sh"
INSTALL_CLI_SHA256="26F0D81F160A3822EF676E4089B7CAB0B7055149CBF503499B6F71BE82EE95EF"

#=================================================
# GITHUB RELEASE INFO FETCHER
#=================================================
# Fetches the latest release version and asset download URL from GitHub.
# Usage: source=$(get_latest_github_release "openclaw" "openclaw")
# Returns: asset_name (e.g., "OpenClaw-2026.5.18.zip")
#
# To get the full URL and SHA256 for a specific asset:
#   release_info=$(get_github_release_info "openclaw" "openclaw" "OpenClaw-{{version}}.zip")
#   url=$(echo "$release_info" | jq -r '.url')
#   sha256=$(echo "$release_info" | jq -r '.sha256')
#=================================================

get_latest_github_release() {
    local repo="$1"
    local asset_name_template="${2:-{{version}}}"

    if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null; then
        ynh_die "get_latest_github_release: curl and jq are required"
    fi

    local api_url="https://api.github.com/repos/${repo}/releases/latest"

    local response
    response="$(curl -fsSL --proto '=https' --tlsv1.2 -H "Accept: application/vnd.github+json" \
        "$api_url" 2>/dev/null)" || {
        ynh_die "Failed to fetch latest release from GitHub API"
    }

    local tag_name
    tag_name="$(echo "$response" | jq -r '.tag_name // empty')" || {
        ynh_die "Failed to parse tag_name from GitHub release"
    }

    if [[ -z "$tag_name" ]] || [[ "$tag_name" == "null" ]]; then
        ynh_die "No release found for ${repo}"
    fi

    local version="${tag_name#v}"

    echo "$version"
}

get_github_asset_info() {
    local repo="$1"
    local asset_pattern="$2"
    local version="${3:-}"

    if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null; then
        ynh_die "get_github_asset_info: curl and jq are required"
    fi

    local api_url
    if [[ -n "$version" ]]; then
        api_url="https://api.github.com/repos/${repo}/releases/tags/v${version}"
    else
        api_url="https://api.github.com/repos/${repo}/releases/latest"
    fi

    local response
    response="$(curl -fsSL --proto '=https' --tlsv1.2 -H "Accept: application/vnd.github+json" \
        "$api_url" 2>/dev/null)" || {
        ynh_die "Failed to fetch release info from GitHub API"
    }

    local tag_name
    tag_name="$(echo "$response" | jq -r '.tag_name // empty')" || {
        ynh_die "Failed to parse tag_name"
    }

    local version_only="${tag_name#v}"

    local assets_json
    assets_json="$(echo "$response" | jq -r '.assets[] | select(.name | match("'"$asset_pattern"'"))')" || {
        ynh_die "No asset matching '${asset_pattern}' found"
    }

    local asset_name
    asset_name="$(echo "$assets_json" | jq -r '.name')" || {
        ynh_die "Failed to parse asset name"
    }

    local browser_download_url
    browser_download_url="$(echo "$assets_json" | jq -r '.browser_download_url')" || {
        ynh_die "Failed to parse download URL"
    }

    echo "${version_only}|${asset_name}|${browser_download_url}"
}

#=================================================
# PATH HELPERS
#=================================================

openclaw_bin() {
    echo "/home/${app}/.openclaw/bin/openclaw"
}

openclaw_state_dir() {
    echo "/home/${app}/.openclaw"
}

node_bin() {
    echo "/home/${app}/.openclaw/tools/node/bin/node"
}

#=================================================
# EXECUTION HELPERS
#=================================================

run_as_openclaw() {
    if [[ $# -eq 0 ]]; then
        ynh_die "run_as_openclaw: no command provided"
    fi

    sudo -u "$app" \
        env HOME="/home/$app" \
            OPENCLAW_STATE_DIR="/home/$app/.openclaw" \
            OPENCLAW_NO_RESPAWN=1 \
            NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache-${app}" \
        "$@"
}

run_as_openclaw_with_timeout() {
    local timeout_seconds="${1:-}"
    shift

    if [[ -z "$timeout_seconds" ]]; then
        run_as_openclaw "$@"
        return
    fi

    if ! [[ "$timeout_seconds" =~ ^[0-9]+$ ]]; then
        ynh_die "run_as_openclaw_with_timeout: timeout must be a positive integer"
    fi

    local start_time
    start_time="$(date +%s)"

    run_as_openclaw "$@" &
    local bg_pid=$!

    while kill -0 "$bg_pid" 2>/dev/null; do
        local elapsed
        elapsed="$(($(date +%s) - start_time))"
        if [[ $elapsed -ge "$timeout_seconds" ]]; then
            kill "$bg_pid" 2>/dev/null || true
            wait "$bg_pid" 2>/dev/null || true
            ynh_die "Command timed out after ${timeout_seconds} seconds"
        fi
        sleep 1
    done

    wait "$bg_pid"
    return $?
}

#=================================================
# DOWNLOAD WITH VERIFICATION
#=================================================

download_verified() {
    local url="$1" dest="$2" expected_sha="$3"

    if [[ -z "$url" ]]; then
        ynh_die "download_verified: url parameter is required"
    fi
    if [[ -z "$dest" ]]; then
        ynh_die "download_verified: destination parameter is required"
    fi
    if [[ -z "$expected_sha" ]]; then
        ynh_die "download_verified: expected_sha parameter is required"
    fi

    if [[ -f "$dest" ]]; then
        rm -f "$dest" || {
            ynh_die "download_verified: failed to remove existing file at $dest"
        }
    fi

    local curl_opts=(
        -fsSL
        --proto '=https'
        --tlsv1.2
        --retry 3
        --retry-delay 2
        --connect-timeout 15
        --max-time 300
        -o "$dest"
    )

    if ! curl "${curl_opts[@]}" "$url"; then
        rm -f "$dest"
        ynh_die "download_verified: failed to download $url"
    fi

    if [[ ! -s "$dest" ]]; then
        rm -f "$dest"
        ynh_die "download_verified: downloaded file is empty"
    fi

    local actual_sha
    actual_sha="$(sha256sum "$dest" 2>/dev/null | awk '{print $1}')" || {
        rm -f "$dest"
        ynh_die "download_verified: failed to compute SHA256 of $dest"
    }

    if [[ -z "$actual_sha" ]]; then
        rm -f "$dest"
        ynh_die "download_verified: computed SHA256 is empty"
    fi

    if [[ "${actual_sha,,}" != "${expected_sha,,}" ]]; then
        rm -f "$dest"
        ynh_die "download_verified: SHA256 mismatch for $url (expected: ${expected_sha:0:16}..., got: ${actual_sha:0:16}...)"
    fi
}

#=================================================
# GATEWAY HEALTH CHECK
#=================================================

wait_for_gateway() {
    local port="$1"
    local max_attempts="${2:-30}"
    local retry_interval="${3:-2}"

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        ynh_print_warn "wait_for_gateway: invalid port '$port'"
        return 1
    fi

    if ! [[ "$max_attempts" =~ ^[0-9]+$ ]]; then
        max_attempts=30
    fi

    if ! [[ "$retry_interval" =~ ^[0-9]+$ ]]; then
        retry_interval=2
    fi

    local attempt=0
    while true; do
        attempt=$((attempt + 1))

        if curl -fsS --connect-timeout 3 --max-time 5 \
            "http://127.0.0.1:${port}/readyz" >/dev/null 2>&1; then
            ynh_print_info "OpenClaw gateway is ready (attempt $attempt)"
            return 0
        fi

        if [[ $attempt -ge $max_attempts ]]; then
            ynh_print_warn "OpenClaw gateway did not become ready after ${max_attempts} attempts"
            return 1
        fi

        sleep "$retry_interval"
    done
}

wait_for_gateway_with_retry() {
    local port="$1"
    local max_wait="${2:-90}"

    if ! [[ "$max_wait" =~ ^[0-9]+$ ]] || [[ "$max_wait" -lt 10 ]]; then
        max_wait=90
    fi

    local start_time
    start_time="$(date +%s)"
    local elapsed=0

    while true; do
        elapsed="$(($(date +%s) - start_time))"

        if curl -fsS --connect-timeout 3 --max-time 5 \
            "http://127.0.0.1:${port}/readyz" >/dev/null 2>&1; then
            ynh_print_info "OpenClaw gateway is ready after ${elapsed}s"
            return 0
        fi

        if [[ $elapsed -ge $max_wait ]]; then
            ynh_print_warn "OpenClaw gateway failed to become ready within ${max_wait}s (elapsed: ${elapsed}s)"
            return 1
        fi

        sleep 2
    done
}

#=================================================
# ARM TUNING
#=================================================

arm_tuning_env() {
    local arch
    arch="$(uname -m 2>/dev/null)" || arch="unknown"

    case "$arch" in
        aarch64|arm64)
            echo "OPENCLAW_NO_RESPAWN=1"
            echo "NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache-${app}"
            ;;
        *)
            echo "OPENCLAW_NO_RESPAWN=1"
            ;;
    esac
}

#=================================================
# VERSION MIGRATION HOOKS
#=================================================

ynh_upgrade_from_v1_to_v2() {
    ynh_print_info "Running migration from v1 to v2..."
    ynh_app_setting_set_default --key=update_channel --value="stable"
    ynh_app_setting_set_default --key=auto_update --value="0"
    ynh_print_info "Migration from v1 to v2 completed"
}

#=================================================
# TOKEN GENERATION
#=================================================

generate_token() {
    local length="${1:-32}"

    if ! [[ "$length" =~ ^[0-9]+$ ]] || [[ "$length" -lt 16 ]]; then
        length=32
    fi

    if command -v openssl &>/dev/null; then
        openssl rand -hex "$length" 2>/dev/null && return 0
    fi

    if [[ -r /dev/urandom ]]; then
        dd if=/dev/urandom bs=1 count="$length" 2>/dev/null | xxd -p && return 0
    fi

    ynh_die "generate_token: failed to generate token - no suitable method available"
}

#=================================================
# JQ WRAPPER HELPERS
#=================================================

jq_read() {
    local json_file="$1"
    local jq_path="$2"
    local default="${3:-}"

    if [[ ! -f "$json_file" ]]; then
        echo "$default"
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        ynh_die "jq is required but not installed"
    fi

    local value
    value="$(jq -r "$jq_path" "$json_file" 2>/dev/null)" || {
        echo "$default"
        return 1
    }

    if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
        echo "$default"
        return 1
    fi

    echo "$value"
    return 0
}

jq_write() {
    local json_file="$1"
    local jq_path="$2"
    local value="$3"

    if [[ ! -f "$json_file" ]]; then
        ynh_die "jq_write: JSON file not found: $json_file"
    fi

    if ! command -v jq &>/dev/null; then
        ynh_die "jq is required but not installed"
    fi

    local tmp_file
    tmp_file="$(mktemp)"

    if ! jq "$jq_path = \"$value\"" "$json_file" > "$tmp_file" 2>/dev/null; then
        rm -f "$tmp_file"
        ynh_die "jq_write: failed to write $jq_path = $value to $json_file"
    fi

    if ! mv "$tmp_file" "$json_file"; then
        rm -f "$tmp_file"
        ynh_die "jq_write: failed to move temp file to $json_file"
    fi

    return 0
}

#=================================================
# PERMISSION HELPERS
#=================================================

ensure_directory_owner() {
    local dir="$1"
    local owner="${2:-$app}"
    local group="${3:-$app}"
    local mode="${4:-755}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi

    chown "$owner:$group" "$dir" || return 1
    chmod "$mode" "$dir" || return 1

    return 0
}

ensure_directory_owner_recursive() {
    local dir="$1"
    local owner="${2:-$app}"
    local group="${3:-$app}"
    local dirmode="${4:-755}"
    local filemode="${5:-644}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi

    chown -R "$owner:$group" "$dir" || return 1
    find "$dir" -type d -exec chmod "$dirmode" {} \; || return 1
    find "$dir" -type f -exec chmod "$filemode" {} \; || return 1

    return 0
}