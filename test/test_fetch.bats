#!/usr/bin/env bats

setup() {
  ROOT="${BATS_TEST_DIRNAME}/.."
  SCR="$ROOT/src/usr/local/emhttp/plugins/komari-agent/scripts"
  PATH="${BATS_TEST_DIRNAME}/helpers/mockbin:$PATH"
  TMP="$(mktemp -d)"
  export KM_FLASH_DIR="$TMP/flash" KM_PLUGIN_DIR="$TMP/plugin"
  export KM_CFG="$KM_FLASH_DIR/komari-agent.cfg" KM_BIN="$KM_PLUGIN_DIR/bin/komari-agent"
  mkdir -p "$KM_FLASH_DIR" "$KM_PLUGIN_DIR/bin"
}
teardown() { rm -rf "$TMP"; }

# seed a cached binary carrying a recognizable marker
seed_cache() {
  printf '#!/bin/sh\n[ "$1" = "--help" ] && exit 0\necho CACHED\n' > "$KM_FLASH_DIR/komari-agent-linux-amd64"
  chmod +x "$KM_FLASH_DIR/komari-agent-linux-amd64"
}

@test "fetch downloads when no cache and not forced" {
  MOCK_UNAME=x86_64 run bash "$SCR/fetch.sh" latest ""
  [ "$status" -eq 0 ]
  [ -f "$KM_FLASH_DIR/komari-agent-linux-amd64" ]
  [ -x "$KM_BIN" ]
}

@test "fetch reuses cache when not forced (no re-download)" {
  seed_cache
  MOCK_UNAME=x86_64 run bash "$SCR/fetch.sh" latest ""
  [ "$status" -eq 0 ]
  grep -q CACHED "$KM_BIN"          # deployed the cached binary, not a fresh download
}

@test "fetch with force re-downloads over cache" {
  seed_cache
  MOCK_UNAME=x86_64 run bash "$SCR/fetch.sh" latest "" force
  [ "$status" -eq 0 ]
  run grep -q CACHED "$KM_BIN"
  [ "$status" -ne 0 ]               # cache marker gone -> it re-downloaded
}

@test "forced fetch skips re-download when version unchanged" {
  seed_cache
  echo "1.2.13" > "$KM_FLASH_DIR/komari-agent-linux-amd64.version"
  MOCK_UNAME=x86_64 MOCK_VERSION=1.2.13 run bash "$SCR/fetch.sh" latest "" force
  [ "$status" -eq 0 ]
  grep -q CACHED "$KM_BIN"                 # redeployed the cache, did NOT download
  echo "$output" | grep -qi "up to date"
}

@test "forced fetch re-downloads when a newer version is available" {
  seed_cache
  echo "1.2.12" > "$KM_FLASH_DIR/komari-agent-linux-amd64.version"
  MOCK_UNAME=x86_64 MOCK_VERSION=1.2.13 run bash "$SCR/fetch.sh" latest "" force
  [ "$status" -eq 0 ]
  run grep -q CACHED "$KM_BIN"
  [ "$status" -ne 0 ]                       # re-downloaded the newer version
  [ "$(cat "$KM_FLASH_DIR/komari-agent-linux-amd64.version")" = "1.2.13" ]
}

@test "forced fetch keeps old cache when verify fails" {
  seed_cache
  BAD=1 MOCK_UNAME=x86_64 run bash "$SCR/fetch.sh" latest "" force
  [ "$status" -ne 0 ]
  [ -f "$KM_FLASH_DIR/komari-agent-linux-amd64" ]
}

@test "forced fetch falls back to cache on download failure" {
  seed_cache
  CURL_FAIL=1 MOCK_UNAME=x86_64 run bash "$SCR/fetch.sh" latest "" force
  [ "$status" -eq 0 ]
  [ -x "$KM_BIN" ]
}
