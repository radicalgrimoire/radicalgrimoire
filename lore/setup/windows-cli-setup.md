# Windows に Lore CLI をインストールする

Windows 端末に Lore CLI をインストールする手順。
この手順全体は通し検証していない。

## 1. 管理者から入手する

* 対象 server と互換性のある Windows 用 CLI の入手先と version

## 2. CLI をインストールする

### 公式インストーラーを使う場合

PowerShell で以下を実行する。公式インストーラーは既定では最新 release を
`%USERPROFILE%\bin` に配置し、ユーザー PATH に追加する。

```powershell
irm https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.ps1 | iex
```

このコマンドは最新版のスクリプトをダウンロードして実行する。事前に
[スクリプトの内容](https://github.com/EpicGames/lore/blob/main/scripts/install.ps1)と、
公式 CLI が対象 server・bridge と互換であることを管理者に確認する。
既存の配置先の `lore.exe` は上書きされるため、先に確認する。
`LORE_VERSION`、`LORE_REPO`、`LORE_INSTALL_DIR`、`LORE_DEMO`、`LORE_SERVER`
などの環境変数が設定されていると、取得元や動作が変わる。

### 管理者から CLI を受け取る場合

管理者から受け取った `lore.exe` を任意のフォルダに配置し、そのフォルダを Windows の
ユーザー PATH に追加する。既存の `lore.exe` は確認せず上書きしない。

### インストール後の確認

PowerShell を開き直し、配置した CLI が見つかることを確認する。

```powershell
Get-Command lore -All
lore --version
```

意図した CLI が表示されない場合は、配置先と PATH を確認する。

証明書の設定は[Windows の証明書設定](../operations/001-tls-troubleshooting.md#3-windows-client--runner-から確認する)、
ログイン以降は [CLI の基本操作](../guides/001-cli-usage.md)を参照する。

