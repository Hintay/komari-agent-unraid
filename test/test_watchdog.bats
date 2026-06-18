#!/usr/bin/env bats

setup() {
  ROOT="${BATS_TEST_DIRNAME}/.."
  SCR="$ROOT/src/usr/local/emhttp/plugins/komari-agent/scripts"
  PATH="${BATS_TEST_DIRNAME}/helpers/mockbin:$PATH"
  TMP="$(mktemp -d)"
  export KM_FLASH_DIR="$TMP/flash" KM_PLUGIN_DIR="$TMP/plugin"
  export KM_CFG="$KM_FLASH_DIR/komari-agent.cfg" KM_BIN="$KM_PLUGIN_DIR/bin/komari-agent"
  export KM_PID="$TMP/komari.pid" KM_LOG="$TMP/komari.log"
  mkdir -p "$KM_FLASH_DIR" "$KM_PLUGIN_DIR/bin"
  printf '#!/bin/sh\nexec sleep 30\n' > "$KM_BIN"; chmod +x "$KM_BIN"
}
teardown() { [ -f "$KM_PID" ] && kill "$(cat "$KM_PID")" 2>/dev/null; rm -rf "$TMP"; }

mkcfg() { printf 'ENABLED="%s"\nENDPOINT="https://p"\nCONN_MODE="token"\nTOKEN="T"\n' "$1" > "$KM_CFG"; }

@test "watchdog starts agent when enabled and not running" {
  mkcfg yes
  bash "$SCR/watchdog.sh"
  run bash "$SCR/rc.komari-agent" status
  [ "$status" -eq 0 ]
}
@test "watchdog does nothing when disabled" {
  mkcfg no
  bash "$SCR/watchdog.sh"
  run bash "$SCR/rc.komari-agent" status
  [ "$status" -ne 0 ]
}
@test "watchdog no-op when already running" {
  mkcfg yes
  bash "$SCR/rc.komari-agent" start
  pid1="$(cat "$KM_PID")"
  bash "$SCR/watchdog.sh"
  [ "$(cat "$KM_PID")" = "$pid1" ]
}
@test "watchdog persists self-updated binary back to flash cache" {
  mkcfg yes
  echo OLD > "$KM_FLASH_DIR/komari-agent-linux-amd64"
  touch -t 202001010000 "$KM_FLASH_DIR/komari-agent-linux-amd64"   # make cache clearly old
  printf '#!/bin/sh\nexec sleep 30\n' > "$KM_BIN"; chmod +x "$KM_BIN"   # newer -> simulates a self-update
  MOCK_UNAME=x86_64 bash "$SCR/watchdog.sh"
  grep -q sleep "$KM_FLASH_DIR/komari-agent-linux-amd64"   # cache refreshed
}
@test "watchdog records latest version on self-update" {
  mkcfg yes
  echo OLD > "$KM_FLASH_DIR/komari-agent-linux-amd64"                    # cache differs from RAM binary
  printf '#!/bin/sh\nexec sleep 30\n' > "$KM_BIN"; chmod +x "$KM_BIN"
  MOCK_UNAME=x86_64 MOCK_VERSION=1.2.13 bash "$SCR/watchdog.sh"
  [ "$(cat "$KM_FLASH_DIR/komari-agent-linux-amd64.version")" = "1.2.13" ]
}
@test "watchdog drops version when latest cannot be resolved" {
  mkcfg yes
  echo OLD > "$KM_FLASH_DIR/komari-agent-linux-amd64"
  echo "9.9.9" > "$KM_FLASH_DIR/komari-agent-linux-amd64.version"
  printf '#!/bin/sh\nexec sleep 30\n' > "$KM_BIN"; chmod +x "$KM_BIN"
  CURL_FAIL=1 MOCK_UNAME=x86_64 bash "$SCR/watchdog.sh"
  [ ! -f "$KM_FLASH_DIR/komari-agent-linux-amd64.version" ]
}
@test "watchdog leaves version alone in steady state (agent running)" {
  mkcfg yes
  echo "1.2.13" > "$KM_FLASH_DIR/komari-agent-linux-amd64.version"
  bash "$SCR/rc.komari-agent" start                                          # agent alive -> fast path
  MOCK_UNAME=x86_64 bash "$SCR/watchdog.sh"
  [ "$(cat "$KM_FLASH_DIR/komari-agent-linux-amd64.version")" = "1.2.13" ]   # untouched, no binary work
}
