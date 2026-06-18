# Komari Agent for Unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Hintay/komari-agent-unraid?sort=semver)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Release date](https://img.shields.io/github/release-date/Hintay/komari-agent-unraid)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Hintay/komari-agent-unraid/total)](https://github.com/Hintay/komari-agent-unraid/releases)
[![License](https://img.shields.io/github/license/Hintay/komari-agent-unraid)](LICENSE)

[English](README.md) | [简体中文](README.zh-CN.md) | **繁體中文** | [日本語](README.ja.md)

在 Unraid 主機上**裸機**運行 [Komari](https://github.com/komari-monitor) 監控 agent 的外掛，即使陣列已停止也能持續回報。支援開機自動啟動、重新開機後設定不遺失、程序當掉時自動重啟。

## 功能

- **裸機運行**：`komari-agent` 直接跑在 Unraid 主機上,而非容器內。
- **多架構支援**：安裝時從 komari-agent releases 下載對應架構(amd64 / arm64 / arm / 386),快取到 USB 隨身碟。
- **重新開機不遺失**：設定存於隨身碟;每次開機重新部署二進位,並在啟用時自動啟動。
- **當機恢復**：每分鐘的看門狗在 agent 掉線時自動重啟。
- **自動更新**：agent 依 semver 自行更新,新版本回寫到隨身碟快取以便重新開機後保留;手動**檢查更新**會在彈出視窗即時顯示進度。
- **設定介面**：Token / 自動探索兩種模式、停用 Web SSH/RCE、以及進階選項;欄位說明點擊展開,日誌即時串流檢視。
- **多語言**：English、简体中文、繁體中文、日本語,跟隨 Unraid 目前語言。

## 需求

- Unraid **6.12.0** 或更新版本。
- 安裝時需可連線 GitHub(或在設定裡配置 GitHub 代理)。

## 安裝

Unraid → **Plugins → Install Plugin**,貼上:

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

然後開啟 **Settings → Komari Agent**,填入**面板位址**與 **Token**(或切到**自動探索**並填叢集金鑰),開啟 **Enabled**,點擊 **Save & Apply**。

若不想讓面板在本機開啟 Web 終端或執行命令,可開啟 **Disable Web SSH/RCE**(預設關閉)。網路存取 GitHub 不順時,可在進階選項的 **GitHub proxy** 填加速前綴(如 `https://ghproxy.com`)後再安裝/更新。

## 設定項

| 欄位 | 說明 |
|---|---|
| Enabled | 開機自動啟動,當機後自動重啟。 |
| 面板位址 | 你的 Komari 面板位址。 |
| 連線方式 | **Token**(註冊單台)或**自動探索**(以叢集金鑰註冊)。 |
| 停用 Web SSH/RCE | 阻止面板在本機開啟 Web 終端 / 執行命令。 |
| 自動更新 Agent | 允許 agent 自行更新到新版本。 |
| 進階 | 回報間隔、忽略不安全憑證、額外參數、固定版本、GitHub 代理。 |

## 運作原理

- 外掛把一個 `rc` 指令碼軟連結到 `/etc/rc.d/` 負責啟停,並安裝一個每分鐘的 cron **看門狗**:掉線則重啟,自動更新的二進位回寫到隨身碟快取。
- agent 從記憶體運行,只有設定和快取的二進位存在 USB 隨身碟上,所以更新與設定都能在重新開機後保留。

## 解除安裝

Unraid → **Plugins** → 移除 **Komari Agent**。會停止 agent、移除 cron 看門狗與 `rc` 軟連結,並刪除外掛檔案和快取的二進位。

## 支援

提交 [issue](https://github.com/Hintay/komari-agent-unraid/issues)。agent 本身見 [Komari 專案](https://github.com/komari-monitor)。

## 致謝

基於 komari-monitor 的 [komari-agent](https://github.com/komari-monitor/komari-agent)(MIT)。

## 授權

[MIT](LICENSE) © Hintay
