# Windows に Lore CLI をインストールする

Windows x64 の利用者向けに `lore.exe` を配置し、Lore Server への初回接続を確認する手順。
実機での Windows client 接続と旧 CLI 手順を基に整理している。
**この手順全体を別環境で通して検証したわけではない。** コマンドや client/server の互換性は、
採用する revision で確認する。

## 1. 準備

管理者から次を確認・入手する。

- 対象 server と互換性を確認済みの Windows x64 用 `lore.exe`、その version と SHA-256。
  Entra ID と TLS gRPC を使う構成では、server だけでなく bridge に対する client の互換性も確認する。
- Lore remote URL（例: `lore://<SERVER_HOST>:41337`）と接続先の certificate または信頼する CA。
  証明書の fingerprint を別の信頼できる経路で確認する。**private key は受け取らない。**
- Entra user の identity binding と、対象 repository のアクセス権。未登録なら
  管理者が [bridge の利用者登録](lore-auth-bridge/010-user-onboarding.md) を行う。

公式 release を使う場合は [Epic Games の Lore releases](https://github.com/EpicGames/lore/releases)
から、管理者が指定した version の Windows x64 archive を選ぶ。旧手順では
`lore-<version>-x86_64-pc-windows-msvc.zip` を使用した。公式版が対象環境の fork や
TLS gRPC と互換であると決めつけず、配布元・version・digest を管理者に確認する。
展開後の `lore.exe` を信頼できる経路で提供された digest と照合する。digest が archive 用なら
展開前の archive と照合し、binary 用なら binary と照合する。

## 2. binary を確認して配置する

PowerShell を開き、管理者から入手した binary の path に置き換える。

```powershell
$source = "C:\Path\To\lore.exe"
Get-FileHash -LiteralPath $source -Algorithm SHA256
```

表示された hash を、管理者から別途確認した SHA-256 と照合する。一致しない、または正しい
digest を確認できない場合は配置せず、管理者に問い合わせる。

初回配置の例。既存の `lore.exe` を上書きしない。

```powershell
$destinationDir = Join-Path $env:USERPROFILE "bin"
$destination = Join-Path $destinationDir "lore.exe"
New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
if (Test-Path -LiteralPath $destination) {
    throw "既存の lore.exe があります。更新手順を確認してください: $destination"
}
Copy-Item -LiteralPath $source -Destination $destination
& $destination --version
if ($LASTEXITCODE -ne 0) {
    throw "Lore CLI の起動確認に失敗しました: $LASTEXITCODE"
}
```

管理者が指定した version を表示することを確認する。

## 3. PATH を設定する

上記の `$destinationDir` をユーザー PATH に追加する。管理者権限は不要。

```powershell
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$entries = @($userPath -split ";" | Where-Object { $_ })
if ($entries -notcontains $destinationDir) {
    [Environment]::SetEnvironmentVariable(
        "Path", (($entries + $destinationDir) -join ";"), "User"
    )
}
```

PowerShell を開き直し、実際に呼ばれる executable と version を確認する。

```powershell
Get-Command lore -All
lore --version
```

別の `lore.exe` が先に表示される場合は PATH の順序を確認する。意図した binary を使うまで
既存の binary を削除・上書きしない。

## 4. certificate を信頼しログインする

自己署名 server certificate を使う構成では、配布された **公開 certificate** の fingerprint を
管理者から確認した値と照合し、Current User の Trusted Root store に追加する。
別途 CA を使う場合は管理者の CA 配布手順に従う。

```powershell
$certificatePath = "C:\Path\To\lore-server.crt"
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePath)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $fingerprint = ($sha256.ComputeHash($certificate.RawData) |
        ForEach-Object { $_.ToString("X2") }) -join ":"
    $fingerprint
}
finally {
    $sha256.Dispose()
    $certificate.Dispose()
}
```

certificate fingerprint は file の SHA-256 hash と同じとは限らない。管理者から別途受け取った
certificate の **SHA-256 fingerprint** と表示を照合し、一致しない場合は import しない。
一致を確認した後:

```powershell
Import-Certificate -FilePath $certificatePath -CertStoreLocation Cert:\CurrentUser\Root
$env:SSL_CERT_FILE = $certificatePath
lore auth login lore://<SERVER_HOST>:41337
```

`SSL_CERT_FILE` は現在の PowerShell session だけに適用される。別の session で必要な場合は
再設定する。client revision により trust store の利用方法が異なるため、TLS error が出た場合は
管理者に確認する。証明書検証を無効化しない。

browser の Entra login を完了する。callback URL を直接開かない。CI runner が Windows service
account で動く場合は Current User ではなく Local Machine trust store が必要になることがある。

## 5. 接続を確認する

管理者から指定された server と repository に置き換える。clone 先には存在しない path を選ぶ。

```powershell
lore repository list lore://<SERVER_HOST>:41337 --remote --no-pager
lore clone lore://<SERVER_HOST>:41337/<REPOSITORY> "C:\Path\To\NewClone"
```

一覧や clone で権限エラーが出る場合は、identity binding と repository grant を管理者に確認する。
login と clone の成功は writer 権限による push の成功を保証しない。

## 更新するとき

管理者が指定した互換 version と digest を確認し、使用中の CLI を終了する。現在の
`lore.exe` の version と配置場所を確認してから、既存 binary を別名で backup し、新 binary を
配置する。更新後は `lore --version` と実際の login / clone を確認する。
旧 client の token store が新 version に自動移行されない場合があるため、再 login する。
問題があれば、管理者と互換性を確認したうえで backup から戻す。
