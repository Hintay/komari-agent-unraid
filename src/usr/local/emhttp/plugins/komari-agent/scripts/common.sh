#!/bin/bash
# Shared helpers for komari-agent unraid plugin. bash 3.2 compatible.

# Paths (override-able for tests)
: "${KM_FLASH_DIR:=/boot/config/plugins/komari-agent}"
: "${KM_PLUGIN_DIR:=/usr/local/emhttp/plugins/komari-agent}"
: "${KM_CFG:=$KM_FLASH_DIR/komari-agent.cfg}"
: "${KM_BIN:=$KM_PLUGIN_DIR/bin/komari-agent}"
: "${KM_PID:=/var/run/komari-agent.pid}"
: "${KM_LOG:=/var/log/komari-agent.log}"
: "${KM_REPO:=komari-monitor/komari-agent}"
: "${KM_AD_FILE:=auto-discovery.json}"

# Map `uname -m` to komari-agent linux arch suffix. Echoes suffix; returns 1 if unsupported.
km_detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)        echo amd64 ;;
    aarch64|arm64)       echo arm64 ;;
    armv7*|armv6*|armv8l) echo arm  ;;
    i386|i686)           echo 386   ;;
    *) return 1 ;;
  esac
}

# Echo the release asset filename for a given arch suffix.
km_asset_name() { echo "komari-agent-linux-$1"; }

# Build the download URL. Args: VERSION ARCH GHPROXY ("" or "latest" version => latest)
km_download_url() {
  local _ver="$1" _arch="$2" _ghp="$3"
  local _base="https://github.com/${KM_REPO}/releases"
  local _p _url
  if [ -z "$_ver" ] || [ "$_ver" = "latest" ]; then _p="latest/download"; else _p="download/$_ver"; fi
  _url="$_base/$_p/$(km_asset_name "$_arch")"
  if [ -n "$_ghp" ]; then _url="${_ghp%/}/$_url"; fi
  echo "$_url"
}

# Resolve the latest release tag from GitHub via the download redirect (a HEAD
# request, no body transfer). Args: ARCH GHPROXY. Echoes the tag, or nothing if
# it cannot be resolved (offline / proxy that drops the redirect).
km_latest_tag() {
  local _arch="$1" _ghp="${2:-}" _url
  _url="$(km_download_url latest "$_arch" "$_ghp")"
  curl -fsSI "$_url" 2>/dev/null | tr -d '\r' \
    | sed -n 's#^[Ll]ocation:[ ]*.*/releases/download/\([^/]*\)/.*#\1#p' | head -n1
}

# Read a value from a KEY="value" cfg file. Args: FILE KEY
km_cfg_get() {
  [ -f "$1" ] || return 0
  sed -n "s/^$2=\"\(.*\)\"\$/\1/p" "$1" | head -n1
}

# Upsert KEY="value" into a cfg file. Args: FILE KEY VALUE
km_cfg_set() {
  local _f="$1" _k="$2" _v="$3" _t
  _t="$(mktemp)"
  touch "$_f"
  grep -v "^$_k=" "$_f" > "$_t" 2>/dev/null || true
  printf '%s="%s"\n' "$_k" "$_v" >> "$_t"
  mv "$_t" "$_f"
}

# Build komari-agent CLI args from cfg vars already in environment. Echoes the arg string.
km_agent_args() {
  # default every cfg var so a missing key (e.g. an older cfg without a newly
  # added option) does not trip `set -u` in callers
  local _a="-e ${ENDPOINT:-}"
  if [ "${CONN_MODE:-}" = "discovery" ]; then
    _a="$_a --auto-discovery ${AD_KEY:-}"
  else
    _a="$_a -t ${TOKEN:-}"
  fi
  # agent self-update stays on unless AUTO_UPDATE != yes, then disable it
  [ "${AUTO_UPDATE:-}" = "yes" ] || _a="$_a --disable-auto-update"
  [ "${DISABLE_WEB_SSH:-}" = "yes" ] && _a="$_a --disable-web-ssh"
  [ -n "${INTERVAL:-}" ] && _a="$_a -i ${INTERVAL}"
  [ "${IGNORE_UNSAFE_CERT:-}" = "yes" ] && _a="$_a -u"
  [ "${GPU:-}" = "yes" ] && _a="$_a --gpu"
  if [ -n "${FILTER_NICS:-}" ]; then
    if [ "${NIC_FILTER:-}" = "include" ]; then _a="$_a --include-nics ${FILTER_NICS}"
    elif [ "${NIC_FILTER:-}" = "exclude" ]; then _a="$_a --exclude-nics ${FILTER_NICS}"; fi
  fi
  [ -n "${EXTRA_ARGS:-}" ] && _a="$_a ${EXTRA_ARGS}"
  echo "$_a"
}

# Ensure the auto-discovery UUID/token file survives Unraid reboots.
#
# The upstream agent stores auto-discovery state beside the executable. On
# Unraid that executable lives under /usr/local/emhttp (RAM), while the plugin's
# durable state lives under /boot/config/plugins. Link the runtime path the
# agent expects to the flash-backed copy before it starts.
km_prepare_auto_discovery_state() {
  local _bin_dir _runtime _persist
  _bin_dir="$(dirname "$KM_BIN")"
  _runtime="$_bin_dir/$KM_AD_FILE"
  _persist="$KM_FLASH_DIR/$KM_AD_FILE"

  mkdir -p "$KM_FLASH_DIR" "$_bin_dir" || return 1

  if [ -d "$_runtime" ]; then
    echo "auto-discovery state path is a directory: $_runtime" >&2
    return 1
  fi

  if [ -e "$_runtime" ] && [ ! -L "$_runtime" ] && [ ! -e "$_persist" ]; then
    cp -p "$_runtime" "$_persist" 2>/dev/null || cp "$_runtime" "$_persist" || return 1
  fi

  if [ -L "$_runtime" ]; then
    local _target
    _target="$(readlink "$_runtime" 2>/dev/null || true)"
    [ "$_target" = "$_persist" ] && return 0
  fi

  rm -f "$_runtime" || return 1
  ln -s "$_persist" "$_runtime"
}

# True (0) if the agent process from KM_PID is alive.
km_is_running() {
  [ -f "$KM_PID" ] || return 1
  local _pid
  _pid="$(cat "$KM_PID" 2>/dev/null)"
  [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null
}
