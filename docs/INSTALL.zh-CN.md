# 安装

[English](INSTALL.md) | **中文**

## 通过 .plg URL（推荐）
unraid → Plugins → Install Plugin，粘贴：
`https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg`

## 配置
Settings → Komari Agent：填面板地址与 Token（或切到 **Auto-discovery** 填 AD Key），勾选 **Enabled**，点击 **Save & Apply**。建议保持 **Disable Web SSH/RCE** 勾选。

国内网络可在 **GitHub proxy** 填加速前缀（如 `https://ghproxy.com`）。

## 卸载
Plugins → Komari Agent → Remove。配置与缓存一并清除。
