#!/usr/bin/env bats

setup() {
  COMMON="${BATS_TEST_DIRNAME}/../src/usr/local/emhttp/plugins/komari-agent/scripts/common.sh"
  MOCK="${BATS_TEST_DIRNAME}/helpers/mockbin"
  PATH="$MOCK:$PATH"
  # shellcheck disable=SC1090
  . "$COMMON"
}

@test "detect_arch maps x86_64 to amd64" {
  MOCK_UNAME=x86_64 run km_detect_arch
  [ "$status" -eq 0 ]; [ "$output" = "amd64" ]
}
@test "detect_arch maps aarch64 to arm64" {
  MOCK_UNAME=aarch64 run km_detect_arch
  [ "$status" -eq 0 ]; [ "$output" = "arm64" ]
}
@test "detect_arch maps armv7l to arm" {
  MOCK_UNAME=armv7l run km_detect_arch
  [ "$status" -eq 0 ]; [ "$output" = "arm" ]
}
@test "detect_arch maps i686 to 386" {
  MOCK_UNAME=i686 run km_detect_arch
  [ "$status" -eq 0 ]; [ "$output" = "386" ]
}
@test "detect_arch fails on unknown" {
  MOCK_UNAME=sparc run km_detect_arch
  [ "$status" -ne 0 ]; [ -z "$output" ]
}
@test "asset name" {
  run km_asset_name arm64
  [ "$output" = "komari-agent-linux-arm64" ]
}
@test "download url latest" {
  run km_download_url latest amd64 ""
  [ "$output" = "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64" ]
}
@test "download url empty version defaults to latest" {
  run km_download_url "" amd64 ""
  [ "$output" = "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64" ]
}
@test "download url pinned version" {
  run km_download_url 1.2.13 arm64 ""
  [ "$output" = "https://github.com/komari-monitor/komari-agent/releases/download/1.2.13/komari-agent-linux-arm64" ]
}
@test "download url with ghproxy" {
  run km_download_url latest amd64 "https://ghproxy.com"
  [ "$output" = "https://ghproxy.com/https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64" ]
}
@test "cfg set then get roundtrip" {
  f="$(mktemp)"
  km_cfg_set "$f" ENDPOINT "https://p.example.com"
  km_cfg_set "$f" TOKEN "abc123"
  km_cfg_set "$f" TOKEN "xyz789"   # overwrite
  run km_cfg_get "$f" ENDPOINT; [ "$output" = "https://p.example.com" ]
  run km_cfg_get "$f" TOKEN;    [ "$output" = "xyz789" ]
  rm -f "$f"
}
@test "cfg get missing key empty" {
  f="$(mktemp)"; run km_cfg_get "$f" NOPE; [ -z "$output" ]; rm -f "$f"
}
@test "agent args token mode, auto-update off keeps disable flag" {
  ENDPOINT="https://p" CONN_MODE="token" TOKEN="T" AUTO_UPDATE="no" DISABLE_WEB_SSH="yes" \
    INTERVAL="2" IGNORE_UNSAFE_CERT="no" EXTRA_ARGS="" \
    run km_agent_args
  [ "$output" = "-e https://p -t T --disable-auto-update --disable-web-ssh -i 2" ]
}
@test "agent args auto-update on omits disable flag" {
  ENDPOINT="https://p" CONN_MODE="token" TOKEN="T" AUTO_UPDATE="yes" DISABLE_WEB_SSH="no" \
    INTERVAL="" IGNORE_UNSAFE_CERT="no" EXTRA_ARGS="" \
    run km_agent_args
  [ "$output" = "-e https://p -t T" ]
}
@test "agent args discovery mode with extra" {
  ENDPOINT="https://p" CONN_MODE="discovery" AD_KEY="K" AUTO_UPDATE="no" DISABLE_WEB_SSH="no" \
    INTERVAL="" IGNORE_UNSAFE_CERT="yes" EXTRA_ARGS="--exclude-nics lo,docker0" \
    run km_agent_args
  [ "$output" = "-e https://p --auto-discovery K --disable-auto-update -u --exclude-nics lo,docker0" ]
}
@test "auto-discovery state is linked to flash storage" {
  tmp="$(mktemp -d)"
  export KM_FLASH_DIR="$tmp/flash" KM_BIN="$tmp/plugin/bin/komari-agent"
  mkdir -p "$(dirname "$KM_BIN")"
  printf '{"uuid":"u","token":"t"}\n' > "$(dirname "$KM_BIN")/auto-discovery.json"

  run km_prepare_auto_discovery_state

  [ "$status" -eq 0 ]
  [ -L "$(dirname "$KM_BIN")/auto-discovery.json" ]
  [ "$(readlink "$(dirname "$KM_BIN")/auto-discovery.json")" = "$KM_FLASH_DIR/auto-discovery.json" ]
  [ "$(cat "$KM_FLASH_DIR/auto-discovery.json")" = '{"uuid":"u","token":"t"}' ]
  rm -rf "$tmp"
}
