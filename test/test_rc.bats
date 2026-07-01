#!/usr/bin/env bats

setup() {
  ROOT="${BATS_TEST_DIRNAME}/.."
  SCR="$ROOT/src/usr/local/emhttp/plugins/komari-agent/scripts"
  TMP="$(mktemp -d)"
  export KM_FLASH_DIR="$TMP/flash" KM_PLUGIN_DIR="$TMP/plugin"
  export KM_CFG="$KM_FLASH_DIR/komari-agent.cfg" KM_BIN="$KM_PLUGIN_DIR/bin/komari-agent"
  export KM_PID="$TMP/komari.pid" KM_LOG="$TMP/komari.log"
  mkdir -p "$KM_FLASH_DIR" "$KM_PLUGIN_DIR/bin"
  printf '#!/bin/sh\nexec sleep 30\n' > "$KM_BIN"; chmod +x "$KM_BIN"
  cat > "$KM_CFG" <<EOF
ENABLED="yes"
ENDPOINT="https://p"
CONN_MODE="token"
TOKEN="T"
DISABLE_WEB_SSH="yes"
EOF
}
teardown() {
  [ -f "$KM_PID" ] && kill "$(cat "$KM_PID")" 2>/dev/null
  rm -rf "$TMP"
}

@test "start then status running" {
  bash "$SCR/rc.komari-agent" start
  run bash "$SCR/rc.komari-agent" status
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi running
}
@test "start is idempotent" {
  bash "$SCR/rc.komari-agent" start
  pid1="$(cat "$KM_PID")"
  bash "$SCR/rc.komari-agent" start
  pid2="$(cat "$KM_PID")"
  [ "$pid1" = "$pid2" ]
}
@test "stop then status stopped" {
  bash "$SCR/rc.komari-agent" start
  bash "$SCR/rc.komari-agent" stop
  run bash "$SCR/rc.komari-agent" status
  [ "$status" -ne 0 ]
}
@test "start fails when binary missing" {
  rm -f "$KM_BIN"
  run bash "$SCR/rc.komari-agent" start
  [ "$status" -ne 0 ]
}
@test "discovery mode links auto-discovery state before start" {
  cat > "$KM_CFG" <<EOF
ENABLED="yes"
ENDPOINT="https://p"
CONN_MODE="discovery"
AD_KEY="K"
DISABLE_WEB_SSH="yes"
EOF
  bash "$SCR/rc.komari-agent" start
  [ -L "$(dirname "$KM_BIN")/auto-discovery.json" ]
  [ "$(readlink "$(dirname "$KM_BIN")/auto-discovery.json")" = "$KM_FLASH_DIR/auto-discovery.json" ]
}
