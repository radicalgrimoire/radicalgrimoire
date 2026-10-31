# Lore CLI の基本操作

Windows から、登録済み repository を取得し変更を送るまでの手順。
旧 CLI 手順と試用ガイドを基に整理した。
コマンドは client revision に依存し、一般化した手順の通し検証は未実施。
本番データではなく、管理者が許可した試用 repository で確認する。

## 1. login と一覧

[Windows CLI のインストール](../setup/001-windows-cli-setup.md) と certificate trust が完了し、管理者が
identity と repository grant を登録した状態で PowerShell を開く。`<...>` を実環境の値に替える。

```powershell
lore --version
if ($LASTEXITCODE -ne 0) { throw "Lore version check failed: $LASTEXITCODE" }
lore auth login lore://<SERVER_HOST>:41337
if ($LASTEXITCODE -ne 0) { throw "Lore login failed: $LASTEXITCODE" }
lore repository list lore://<SERVER_HOST>:41337 --remote --no-pager
if ($LASTEXITCODE -ne 0) { throw "Repository listing failed: $LASTEXITCODE" }
```

browser の Entra login を完了し、利用対象が一覧に表示されることを確認する。認可エラーや
repository が見えない場合は管理者に連絡し、勝手に権限や repository を作り直さない。

## 2. clone と確認

既存の directory を消さず、まだ存在しない clone 先を指定する。

```powershell
lore clone `
  lore://<SERVER_HOST>:41337/<REPOSITORY> `
  "C:\Path\To\NewClone"
if ($LASTEXITCODE -ne 0) { throw "Lore clone failed: $LASTEXITCODE" }
Set-Location -LiteralPath "C:\Path\To\NewClone"
lore repository status
```

clone が成功し working tree と `.lore` が作成されたことを確認する。command が失敗した場合は
次へ進まない。

## 3. 変更、stage、commit、push

専用の試用 repository で、自分の test file を作る。既存 file と衝突する場合は別名を選ぶ。

```powershell
$ErrorActionPreference = 'Stop'
$file = "hello-$env:USERNAME.txt"
if (Test-Path -LiteralPath $file) {
    throw "File already exists: $file"
}
Set-Content -LiteralPath $file -Value "Hello from $env:USERNAME"
lore stage $file
if ($LASTEXITCODE -ne 0) { throw "Lore stage failed: $LASTEXITCODE" }
lore commit "Add trial file"
if ($LASTEXITCODE -ne 0) { throw "Lore commit failed: $LASTEXITCODE" }
lore push
if ($LASTEXITCODE -ne 0) { throw "Lore push failed: $LASTEXITCODE" }
```

各 command の成功を確認する。commit は local revision を作り、push が server に送信する。
権限エラーの場合は管理者に確認する。実際の writer 操作は他の利用者に影響しない場所で試す。

## 4. 更新履歴と問題の切り分け

```powershell
lore repository status
lore revision history --oneline 10
```

利用可能な subcommand は `lore --help` と各 subcommand の `--help` で確認する。
ログインや TLS error は [TLS の確認と切り分け](../operations/001-tls-troubleshooting.md)、権限の確認は
管理者向け [authctl 手順](002-authctl.md) を参照する。token や secret を含む出力を共有しない。
