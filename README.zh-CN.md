# komari-agent-unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)

[English](README.md) | **中文**

在 unraid 宿主机上裸金属运行 [Komari](https://github.com/komari-monitor) 监控 agent 的插件，支持开机自启、重启后配置不丢、进程崩溃自动拉起。

- **设置界面**：Settings → Komari Agent
- **按架构二进制**：安装时从 komari-agent releases 下载对应架构（amd64/arm64/arm/386），缓存到 U 盘。

## 安装

unraid → Plugins → Install Plugin，粘贴：

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

然后打开 **Settings → Komari Agent**，填入面板地址与 Token，勾选 **Enabled**，点击 **Save & Apply**。

详见 [docs/INSTALL.zh-CN.md](docs/INSTALL.zh-CN.md) 与 [docs/TESTING.zh-CN.md](docs/TESTING.zh-CN.md)。
