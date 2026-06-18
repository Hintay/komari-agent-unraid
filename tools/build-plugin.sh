#!/bin/bash
# Build the .txz package and render the .plg from the template.
# Usage: tools/build-plugin.sh <version> <github_owner/repo>
set -eu
VERSION="${1:?usage: build-plugin.sh <version> <owner/repo>}"
REPO="${2:?usage: build-plugin.sh <version> <owner/repo>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
PKG="$BUILD/komari-agent.txz"
rm -rf "$BUILD"; mkdir -p "$BUILD"

# ensure scripts are executable in the package
chmod +x "$ROOT"/src/usr/local/emhttp/plugins/komari-agent/scripts/* 2>/dev/null || true

# build .txz from the src tree (paths mirror the live filesystem)
tar -C "$ROOT/src" -cJf "$PKG" .

# md5 (cross-platform: coreutils md5sum on Linux/unraid, md5 on macOS)
if command -v md5sum >/dev/null 2>&1; then
  MD5="$(md5sum "$PKG" | awk '{print $1}')"
else
  MD5="$(md5 -q "$PKG")"
fi
echo "$MD5  komari-agent.txz" > "$PKG.md5"

# render .plg: inject CHANGELOG at @CHANGELOG@ first, then substitute
# placeholders — so the CHANGELOG's own @VERSION@ (latest entry) gets the tag too
awk -v cl="$ROOT/CHANGELOG.md" '/@CHANGELOG@/{while((getline line < cl)>0) print line; close(cl); next} 1' \
    "$ROOT/plugin/komari-agent.plg.tmpl" \
  | sed -e "s|@VERSION@|$VERSION|g" \
        -e "s|@REPO@|$REPO|g" \
        -e "s|@TXZMD5@|$MD5|g" \
  > "$ROOT/plugin/komari-agent.plg"

echo "built: $PKG (md5=$MD5)"
echo "rendered: $ROOT/plugin/komari-agent.plg"
