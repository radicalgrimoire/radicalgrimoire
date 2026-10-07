# LORE CLI の利用

Lore CLI の公式ドキュメント:

- https://epicgames.github.io/lore/
- https://github.com/EpicGames/lore

Lore Server の構築、永続 store、systemd 設定は
[LORE Server の構築・運用](./lore-server.md) を参照する。server binary の release 更新は
[LORE Server の更新](./lore-server-update.md) を参照する。

## インストール

Windows PowerShell で実行する。

```powershell
irm https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.ps1 | iex
```

更新後は version を確認する。

```powershell
lore --version
```

## Windows CLI の更新

通常は公式 installer を再実行して更新できる。

```powershell
irm https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.ps1 | iex
lore --version
```

既存の install location を維持し、特定 release に更新する場合は GitHub Release の Windows
x64 archive を使う。以下は `v0.10.1` を既存の `C:\Users\<USER>\bin\lore.exe` に配置し、
旧 binary を backup する例である。

```powershell
$ErrorActionPreference = "Stop"

$version = "v0.10.1"
$destination = "$env:USERPROFILE\bin\lore.exe"
$backup = "$env:USERPROFILE\bin\lore.exe.v0.8.3-backup"
$url = "https://github.com/EpicGames/lore/releases/download/$version/lore-$version-x86_64-pc-windows-msvc.zip"
$work = Join-Path $env:TEMP "lore-$version-$([guid]::NewGuid())"

New-Item -ItemType Directory -Path $work | Out-Null
try {
  Invoke-WebRequest -Uri $url -OutFile (Join-Path $work "lore.zip")
  Expand-Archive -LiteralPath (Join-Path $work "lore.zip") `
    -DestinationPath (Join-Path $work "extract")

  $newBinary = Get-ChildItem -LiteralPath (Join-Path $work "extract") `
    -Filter "lore.exe" -File -Recurse | Select-Object -First 1
  if (-not $newBinary) {
    throw "Release archive did not contain lore.exe."
  }

  Copy-Item -LiteralPath $destination -Destination $backup -Force
  Copy-Item -LiteralPath $newBinary.FullName -Destination $destination -Force
  & $destination --version
}
finally {
  Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
```

この PC では `C:\Users\ueno.s\bin\lore.exe` を `v0.10.1` に更新し、旧 `v0.8.3` binary を
`C:\Users\ueno.s\bin\lore.exe.v0.8.3-backup` に保存した。

更新後は認証 token store が旧 version と分かれる場合があるため、Lore Server へ再ログインする。

```powershell
lore auth login lore://172.20.12.193:41337
```

## 認証

Entra ID を使う server へ接続する場合、最初にログインする。

```powershell
lore auth login lore://172.20.12.193:41337
```

Lore 0.9 以降では旧 client の token を自動移行しない。CLI を更新した後は再ログインする。

## 起動チェック

server 側では、HTTP health check に port `41339`、repository 操作に port `41337` の
`lore://` endpoint を使う。

```powershell
lore repository list lore://172.20.12.193:41337 --remote --no-pager
```

## repository 作成

repository は organization を含む名前で作成する。以下は
`gamestudio/UnrealEngine` を `D:\UnrealEngine` に作成する例である。

```powershell
New-Item -ItemType Directory -Force D:\UnrealEngine

lore repository create `
  lore://172.20.12.193:41337/gamestudio/UnrealEngine `
  --repository D:\UnrealEngine
```

作成後、auth bridge が作成者の grant を自動作成しない場合がある。repository が一覧に
現れない、clone できない場合は server 管理者に `writer` grant を依頼する。

## repository 確認

```powershell
lore repository list lore://172.20.12.193:41337 --remote --no-pager
lore repository info lore://172.20.12.193:41337/gamestudio/UnrealEngine
```

## clone

作成済み repository を別 directory へ取得する。

```powershell
lore clone `
  lore://172.20.12.193:41337/gamestudio/UnrealEngine `
  D:\UnrealEngine-Clone
```

repository を作成した directory は最初の working copy なので、同じ directory へ clone
する必要はない。

## ファイルを追加・編集する

working copy 内で変更を stage する。

```powershell
cd D:\UnrealEngine
lore stage .\test.txt
```

追加、編集、削除、ファイル移動をまとめて stage する場合も `lore stage` を使う。

## commit

```powershell
lore commit "add test.txt"
```

## push

```powershell
lore push
```
