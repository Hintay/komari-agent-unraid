#!/bin/bash
# Cron-driven keepalive (every minute) + self-update persistence.
# The agent updates its own RAM binary and then exits with code 42, relying on
# us to restart it. So the steady-state tick is just a cheap liveness check; the
# expensive work (a 12MB binary compare/copy from the USB flash, and a GitHub
# lookup) only runs on the rare occasion the agent is found down.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/common.sh"

[ -f "$KM_CFG" ] || exit 0
[ "$(km_cfg_get "$KM_CFG" ENABLED)" = "yes" ] || exit 0

km_is_running && exit 0          # fast path: alive -> nothing to do

# Agent is down (self-update or crash): restart it, then persist a self-update —
# if the RAM binary now differs from the flash cache the agent rewrote itself,
# so copy it back (survives reboots) and record the version it moved to (the
# current latest release) for the UI's Check Update.
"$HERE/rc.komari-agent" start

arch="$(km_detect_arch 2>/dev/null)" || arch=""
if [ -n "$arch" ]; then
  cache="$KM_FLASH_DIR/$(km_asset_name "$arch")"
  if [ -f "$KM_BIN" ] && ! cmp -s "$KM_BIN" "$cache" 2>/dev/null; then
    cp -f "$KM_BIN" "$cache"
    tag="$(km_latest_tag "$arch" "$(km_cfg_get "$KM_CFG" GHPROXY)")"
    if [ -n "$tag" ]; then printf '%s\n' "$tag" > "$cache.version"; else rm -f "$cache.version"; fi
  fi
fi
