# Installation

**English** | [中文](INSTALL.zh-CN.md)

## Via .plg URL (recommended)
unraid → Plugins → Install Plugin, paste:
`https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg`

## Configure
Settings → Komari Agent: fill in the panel endpoint and Token (or switch to **Auto-discovery** and fill the AD Key), check **Enabled**, then **Save & Apply**. Keep **Disable Web SSH/RCE** checked (recommended).

For networks with limited GitHub access, set a proxy prefix in **GitHub proxy** (e.g. `https://ghproxy.com`).

## Uninstall
Plugins → Komari Agent → Remove. Config and cache are removed together.
