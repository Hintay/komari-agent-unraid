# Komari Agent for Unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Hintay/komari-agent-unraid?sort=semver)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Release date](https://img.shields.io/github/release-date/Hintay/komari-agent-unraid)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Hintay/komari-agent-unraid/total)](https://github.com/Hintay/komari-agent-unraid/releases)
[![License](https://img.shields.io/github/license/Hintay/komari-agent-unraid)](LICENSE)

[English](README.md) | **简体中文** | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md)

在 Unraid 宿主机上**裸金属**运行 [Komari](https://github.com/komari-monitor) 监控 agent 的插件，即使阵列已停止也能持续上报。支持开机自启、重启后配置不丢、进程崩溃自动拉起。

## 功能

- **裸金属运行**：`komari-agent` 直接跑在 Unraid 宿主机上,而非容器内。
- **多架构支持**：安装时从 komari-agent releases 下载对应架构(amd64 / arm64 / arm / 386),缓存到 U 盘。
- **重启不丢**：配置存于 U 盘;每次开机重新部署二进制,并在启用时自动启动。
- **崩溃恢复**:每分钟的看门狗在 agent 掉线时自动重启。
- **自动更新**:agent 自行按 semver 更新,新版本回写到 U 盘缓存以便重启后保留;手动**检查更新**会在弹窗里实时显示进度。
- **设置界面**:Token / 自动发现两种模式、禁用 Web SSH/RCE、以及高级选项;字段帮助点击展开,日志实时流式查看。
- **多语言**:English、简体中文、繁體中文、日本語,跟随 Unraid 当前语言。

## 要求

- Unraid **6.12.0** 或更高版本。
- 安装时需可访问 GitHub(或在设置里配置 GitHub 代理)。

## 安装

Unraid → **Plugins → Install Plugin**,粘贴:

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

然后打开 **Settings → Komari Agent**,填入**面板地址**与 **Token**(或切到**自动发现**并填集群密钥),打开 **Enabled**,点击 **Save & Apply**。

若不想让面板在本机开启 Web 终端或执行命令,可打开 **Disable Web SSH/RCE**(默认关闭)。若 GitHub 访问不畅，可在高级选项的 **GitHub proxy** 填加速前缀(如 `https://ghproxy.com`)后再安装/更新。

## 配置项

| 字段 | 说明 |
|---|---|
| Enabled | 开机自启,崩溃后自动重启。 |
| 面板地址 | 你的 Komari 面板地址。 |
| 连接方式 | **Token**(注册单台)或**自动发现**(用集群密钥注册)。 |
| 禁用 Web SSH/RCE | 阻止面板在本机开启 Web 终端 / 执行命令。 |
| 自动更新 Agent | 允许 agent 自行更新到新版本。 |
| 高级 | 上报间隔、忽略不安全证书、附加参数、固定版本、GitHub 代理。 |

## 工作原理

- 插件把一个 `rc` 脚本软链到 `/etc/rc.d/` 负责启停,并安装一个每分钟的 cron **看门狗**:掉线则重启,自动更新的二进制回写到 U 盘缓存。
- agent 从内存运行,只有配置和缓存的二进制存在 U 盘上,所以更新与设置都能在重启后保留。

## 卸载

Unraid → **Plugins** → 移除 **Komari Agent**。会停止 agent、移除 cron 看门狗与 `rc` 软链,并删除插件文件和缓存的二进制。

## 支持

提交 [issue](https://github.com/Hintay/komari-agent-unraid/issues)。agent 本身见 [Komari 项目](https://github.com/komari-monitor)。

## 致谢

基于 komari-monitor 的 [komari-agent](https://github.com/komari-monitor/komari-agent)(MIT)。

## 许可

[MIT](LICENSE) © Hintay
