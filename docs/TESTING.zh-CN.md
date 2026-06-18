# 集成测试清单（在 unraid VM / 测试机执行）

[English](TESTING.md) | **中文**

前置：已发布一个 release（push 日期 tag 触发 release workflow），或本地构建后手动测试。

1. 安装：Plugins → Install Plugin → 粘贴 .plg URL → Install。
   - [ ] 安装无报错，日志出现 "komari-agent installed"。
   - [ ] Settings → Komari Agent 页面可打开。
2. 配置并启动：
   - [ ] 填 Endpoint + Token，勾选 Enabled + Disable Web SSH，Save & Apply。
   - [ ] Status 显示 running，Komari 面板看到本机上线。
3. 架构正确性：
   - [ ] `uname -m` 与 `/boot/config/plugins/komari-agent/` 下缓存文件名后缀一致。
4. 重启持久化（核心验收）：
   - [ ] 重启 unraid → 开机后无人工干预，Status running，面板自动恢复上线。
5. 崩溃保活：
   - [ ] `kill $(cat /var/run/komari-agent.pid)` → 一分钟内 Status 自动恢复 running。
6. 停用语义：
   - [ ] 点 Stop → Status stopped；等 2 分钟不被看门狗拉回。
   - [ ] 重启 unraid → 仍保持 stopped（ENABLED=no 生效）。
7. 离线缓存：
   - [ ] 断网后重启 unraid → 用 U 盘缓存仍能启动。
8. 更新：
   - [ ] VERSION 改具体 tag，Check Update → 缓存被替换，agent 重启为新版本。
9. 卸载：
   - [ ] 移除插件 → 进程停止、`/etc/cron.d/komari-agent` 与 `/etc/rc.d/rc.komari-agent` 清除、目录清理干净。
