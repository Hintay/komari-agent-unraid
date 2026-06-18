# komari-agent-unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)

**English** | [中文](README.zh-CN.md)

unraid plugin that runs the [Komari](https://github.com/komari-monitor) monitoring agent on the bare-metal host, with auto-start on boot, persistent config across reboots, and crash recovery.

- **Settings UI**: Settings → Komari Agent
- **Per-arch binary**: downloaded (amd64/arm64/arm/386) from the komari-agent releases at install time and cached on the USB flash.

## Install

unraid → Plugins → Install Plugin, paste:

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

Then open **Settings → Komari Agent**, fill in the panel endpoint and Token, check **Enabled**, and **Save & Apply**.

See [docs/INSTALL.md](docs/INSTALL.md) and [docs/TESTING.md](docs/TESTING.md).
