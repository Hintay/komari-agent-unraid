# Komari Agent for Unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Hintay/komari-agent-unraid?sort=semver)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Release date](https://img.shields.io/github/release-date/Hintay/komari-agent-unraid)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Hintay/komari-agent-unraid/total)](https://github.com/Hintay/komari-agent-unraid/releases)
[![License](https://img.shields.io/github/license/Hintay/komari-agent-unraid)](LICENSE)

**English** | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md)

An Unraid plugin that runs the [Komari](https://github.com/komari-monitor) monitoring agent on the bare-metal host, so it keeps reporting even while the array is stopped, with auto-start on boot, config that persists across reboots, and automatic crash recovery.

## Features

- **Bare-metal agent**: runs `komari-agent` directly on the Unraid host, not in a container.
- **Per-architecture binary**: downloads the matching build (amd64 / arm64 / arm / 386) from the komari-agent releases and caches it on the USB flash.
- **Survives reboots**: config is stored on the flash; the binary is re-deployed and (if enabled) started on every boot.
- **Crash recovery**: a per-minute watchdog restarts the agent if it dies.
- **Self-update**: the agent updates itself following semver; the new build is synced back to the flash cache so it survives reboots. A manual **Check Update** shows live progress in a popup.
- **Settings UI**: Token / Auto-discovery modes, Disable Web SSH/RCE, and advanced options, with click-to-show field help and live log streaming.
- **Multi-language**: English, 简体中文, 繁體中文, 日本語, following Unraid's active language.

## Requirements

- Unraid **6.12.0** or newer.
- Outbound internet access to GitHub at install time (or set a GitHub proxy in the settings).

## Install

Unraid → **Plugins → Install Plugin**, paste:

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

Then open **Settings → Komari Agent**, fill in the **Panel endpoint** and **Token** (or switch to **Auto-discovery** and enter the cluster key), turn **Enabled** on, and click **Save & Apply**.

Turn on **Disable Web SSH/RCE** (off by default) if you don't want the panel to open a web shell or run commands on this host. If GitHub is slow or blocked, set a **GitHub proxy** prefix (e.g. `https://ghproxy.com`) in the advanced options before installing/updating.

## Configuration

| Field | Description |
|---|---|
| Enabled | Auto-start on boot and restart on crash. |
| Panel endpoint | Address of your Komari panel. |
| Connection mode | **Token** (register one server) or **Auto-discovery** (register with a cluster key). |
| Disable Web SSH/RCE | Block the panel from opening a web shell / running commands on this host. |
| Auto-update agent | Let the agent update itself to new releases. |
| Advanced | Report interval, ignore unsafe cert, extra args, pinned version, GitHub proxy. |

## How it works

- The plugin links an `rc` script into `/etc/rc.d/` for start/stop and installs a cron **watchdog** (every minute) that restarts the agent if it is down and persists a self-updated binary back to the flash cache.
- The agent runs from RAM; only the config and the cached binary live on the USB flash, so updates and settings survive reboots.

## Uninstall

Unraid → **Plugins** → remove **Komari Agent**. This stops the agent, removes the cron watchdog and the `rc` link, and deletes the plugin files and cached binary.

## Support

Open an [issue](https://github.com/Hintay/komari-agent-unraid/issues). For the agent itself, see the [Komari project](https://github.com/komari-monitor).

## Credits

Built on [komari-agent](https://github.com/komari-monitor/komari-agent) by komari-monitor (MIT).

## License

[MIT](LICENSE) © Hintay
