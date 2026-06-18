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

# format commits in a range into categorized sections (user-facing only)
format_log() {
  local subs
  subs=$(git log --format='%s' --no-decorate $1)
  [ -z "$subs" ] && return 0
  local feat fix improve
  feat=$(echo "$subs" | grep -E '^feat(\(|:)' | sed 's/^feat[^:]*:[[:space:]]*//' || true)
  fix=$(echo "$subs" | grep -E '^fix(\(|:)' | sed 's/^fix[^:]*:[[:space:]]*//' || true)
  improve=$(echo "$subs" | grep -E '^(refactor|simplify|perf)(\(|:)' | sed 's/^[a-z]*[^:]*:[[:space:]]*//' || true)
  ucfirst() { awk '{print "- " toupper(substr($0,1,1)) substr($0,2)}'; }
  if [ -n "$feat" ]; then echo "**New Features**"; echo; echo "$feat" | ucfirst; echo; fi
  if [ -n "$fix" ]; then echo "**Bug Fixes**"; echo; echo "$fix" | ucfirst; echo; fi
  if [ -n "$improve" ]; then echo "**Improvements**"; echo; echo "$improve" | ucfirst; echo; fi
}

# generate changelog from git tags (newest first)
CL="$(mktemp)"
tags=($(git tag --sort=-creatordate 2>/dev/null)) || tags=()
for ((i=0; i<${#tags[@]}; i++)); do
  echo "###${tags[$i]}###"
  if ((i+1 < ${#tags[@]})); then
    format_log "${tags[$i+1]}..${tags[$i]}"
  else
    format_log "${tags[$i]}"
  fi
done > "$CL"

# render .plg: inject changelog at @CHANGELOG@, then substitute placeholders
awk -v cl="$CL" '/@CHANGELOG@/{while((getline line < cl)>0) print line; close(cl); next} 1' \
    "$ROOT/plugin/komari-agent.plg.tmpl" \
  | sed -e "s|@VERSION@|$VERSION|g" \
        -e "s|@REPO@|$REPO|g" \
        -e "s|@TXZMD5@|$MD5|g" \
  > "$ROOT/plugin/komari-agent.plg"
rm -f "$CL"

echo "built: $PKG (md5=$MD5)"
echo "rendered: $ROOT/plugin/komari-agent.plg"
