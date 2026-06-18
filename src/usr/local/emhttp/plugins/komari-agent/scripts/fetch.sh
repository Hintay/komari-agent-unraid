#!/bin/bash
# Download komari-agent for the host arch, verify, cache on flash, deploy to RAM.
# Usage: fetch.sh [VERSION] [GHPROXY] [FORCE]
#   FORCE non-empty -> "Check Update": resolve the release tag, re-download only
#                      if it differs from what is already installed.
#   FORCE empty     -> reuse the existing flash cache if present, so plugin
#                      install / reboot does NOT re-download the binary.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/common.sh"

VERSION="${1:-latest}"
GHPROXY="${2:-}"
FORCE="${3:-}"

log() { echo "[fetch] $*"; }

arch="$(km_detect_arch)" || { log "unsupported arch: $(uname -m)"; exit 1; }
cache="$KM_FLASH_DIR/$(km_asset_name "$arch")"
verfile="$cache.version"          # records the release tag currently on disk
mkdir -p "$KM_FLASH_DIR" "$(dirname "$KM_BIN")"

# Reuse cached binary unless forced (avoids re-downloading on every plugin
# install / reboot). UI "Check Update" passes FORCE to refresh the version.
if [ -z "$FORCE" ] && [ -s "$cache" ]; then
  install -m 0755 "$cache" "$KM_BIN"
  log "using cached binary (arch=$arch); skip download"
  exit 0
fi

url="$(km_download_url "$VERSION" "$arch" "$GHPROXY")"

# Resolve the target release tag so we can report the real version and skip the
# download when it is unchanged. A pinned VERSION is already the tag; for
# "latest" a HEAD request reveals it in the redirect Location (no body
# transfer). If resolution fails (offline / proxy), fall through and download.
target="$VERSION"
if [ "$VERSION" = latest ]; then
  loc="$(km_latest_tag "$arch" "$GHPROXY")"
  [ -n "$loc" ] && target="$loc"
fi

# Already on this exact version -> just (re)deploy the cache, no download.
if [ "$target" != latest ] && [ -s "$cache" ] && [ -f "$verfile" ] \
   && [ "$(cat "$verfile" 2>/dev/null)" = "$target" ]; then
  install -m 0755 "$cache" "$KM_BIN"
  log "already up to date (arch=$arch version=$target)"
  exit 0
fi

tmp="$(mktemp)"
log "downloading version=$target (arch=$arch)"
if ! curl -fsSL -o "$tmp" "$url"; then
  log "download failed"; rm -f "$tmp"
  [ -f "$cache" ] && { log "falling back to cache"; install -m 0755 "$cache" "$KM_BIN"; exit 0; }
  exit 1
fi

# integrity: non-empty + executable self-check via --help
if [ ! -s "$tmp" ]; then log "empty download"; rm -f "$tmp"; exit 1; fi
chmod +x "$tmp"
if ! "$tmp" --help >/dev/null 2>&1; then
  log "verify failed (--help non-zero); keeping existing cache"
  rm -f "$tmp"; exit 1
fi

# atomic replace cache, record the version, then deploy
mv "$tmp" "$cache"
install -m 0755 "$cache" "$KM_BIN"
if [ "$target" != latest ]; then
  printf '%s\n' "$target" > "$verfile"
else
  rm -f "$verfile"          # version unknown -> don't claim one next time
fi
log "installed arch=$arch version=$target"
