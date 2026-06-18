# Komari Agent for Unraid

[![CI](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml/badge.svg)](https://github.com/Hintay/komari-agent-unraid/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Hintay/komari-agent-unraid?sort=semver)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Release date](https://img.shields.io/github/release-date/Hintay/komari-agent-unraid)](https://github.com/Hintay/komari-agent-unraid/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Hintay/komari-agent-unraid/total)](https://github.com/Hintay/komari-agent-unraid/releases)
[![License](https://img.shields.io/github/license/Hintay/komari-agent-unraid)](LICENSE)

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | **日本語**

[Komari](https://github.com/komari-monitor) 監視エージェントを Unraid ホスト上で**ベアメタル**実行する Unraid プラグインです。アレイが停止していても報告を続けられ、起動時の自動開始、再起動をまたぐ設定の保持、クラッシュ時の自動復旧に対応します。

## 機能

- **ベアメタル実行**：`komari-agent` をコンテナではなく Unraid ホスト上で直接実行します。
- **アーキテクチャ別バイナリ**：komari-agent のリリースから対応するビルド(amd64 / arm64 / arm / 386)をダウンロードし、USB フラッシュにキャッシュします。
- **再起動後も保持**：設定はフラッシュに保存され、起動のたびにバイナリを再配置し(有効なら)起動します。
- **クラッシュ復旧**：毎分のウォッチドッグがエージェント停止時に再起動します。
- **自己更新**：エージェントが自身を更新し(semver)、新しいビルドはフラッシュのキャッシュへ書き戻されて再起動後も保持されます。手動の **Check Update** はポップアップで進捗をライブ表示します。
- **設定 UI**：Token / 自動検出モード、Web SSH/RCE の無効化、詳細オプション。フィールドのヘルプはクリックで表示、ログはライブストリーミング。
- **多言語**：English、简体中文、繁體中文、日本語。Unraid の現在の言語に追従します。

## 要件

- Unraid **6.12.0** 以降。
- インストール時に GitHub へのアウトバウンド接続(または設定で GitHub プロキシを指定)。

## インストール

Unraid → **Plugins → Install Plugin** で次を貼り付けます:

```
https://github.com/Hintay/komari-agent-unraid/releases/latest/download/komari-agent.plg
```

次に **Settings → Komari Agent** を開き、**パネルのアドレス**と **Token** を入力し(または **自動検出** に切り替えてクラスターキーを入力)、**Enabled** をオンにして **Save & Apply** をクリックします。

パネルにこのホストで Web シェルを開いたりコマンドを実行させたくない場合は、**Disable Web SSH/RCE**(既定はオフ)をオンにします。GitHub が遅い/ブロックされる場合は、インストール/更新の前に詳細オプションの **GitHub proxy** にプロキシのプレフィックス(例:`https://ghproxy.com`)を設定してください。

## 設定項目

| 項目 | 説明 |
|---|---|
| Enabled | 起動時に自動開始し、クラッシュ時に再起動。 |
| パネルのアドレス | Komari パネルのアドレス。 |
| 接続方式 | **Token**(1台を登録)または **自動検出**(クラスターキーで登録)。 |
| Disable Web SSH/RCE | パネルが Web シェルを開いたりコマンドを実行するのを禁止。 |
| 自動更新 Agent | エージェントの新リリースへの自己更新を許可。 |
| 詳細 | 送信間隔、安全でない証明書の無視、追加の引数、バージョン固定、GitHub プロキシ。 |

## 仕組み

- プラグインは `rc` スクリプトを `/etc/rc.d/` にシンボリックリンクして起動/停止を担当し、毎分の cron **ウォッチドッグ** をインストールします。停止していれば再起動し、自己更新されたバイナリをフラッシュのキャッシュへ書き戻します。
- エージェントは RAM から実行され、USB フラッシュ上には設定とキャッシュされたバイナリのみが残るため、更新と設定は再起動後も保持されます。

## アンインストール

Unraid → **Plugins** で **Komari Agent** を削除します。エージェントを停止し、cron ウォッチドッグと `rc` リンクを除去し、プラグインファイルとキャッシュされたバイナリを削除します。

## サポート

[Issue](https://github.com/Hintay/komari-agent-unraid/issues) を作成してください。エージェント本体は [Komari プロジェクト](https://github.com/komari-monitor) を参照してください。

## クレジット

komari-monitor による [komari-agent](https://github.com/komari-monitor/komari-agent)(MIT)をベースにしています。

## ライセンス

[MIT](LICENSE) © Hintay
