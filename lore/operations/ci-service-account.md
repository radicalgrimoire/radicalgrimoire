# CI Service Account の設定

ブラウザー login ができない Windows runner から Lore を利用するための手順。
[193 の作業記録](../work/server-193-service-account.md) と
[215 の作業記録](../work/server-215-20261022-03.md) を基に一般化した。
実機では GitHub Actions self-hosted runner の login と clone が成功している。
**Jenkins 本番 runner の login および writer の commit / push は、この一般化手順では未検証。**

## 1. 事前確認

- Service Account 対応 bridge と、server / bridge に互換な Windows CLI を用意する。
- `lore-authctl service-account --help` と各 subcommand の help を対象 revision で確認する。
- 使用する repository、最小 role、実際の runner source IP / CIDR を確定する。NAT や proxy を
  経由する場合、runner の表示 IP と bridge が見る IP が違うことがある。
- bridge gRPC endpoint `https://<SERVER_HOST>:8081` と Lore remote
  `lore://<SERVER_HOST>:41337` を区別する。
- client secret、token を repository、job log、shell history、共有 terminal に残さない。
  credential store と runner のアクセス権を制限する。

## 2. Service Account と権限

bridge host の管理者 shell で実行する。`add` は user ID、client ID、secret を一度だけ出力する。
次の例は出力をログに表示しないための一時 file を作る。安全な管理端末と非共有 shell を使い、
file の取り扱いは組織の secret 管理手順に従う。

先に所属先の group を用意する。既存 group を使う場合は作成を省略する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  group add "<GROUP>" --description "CI runners"
umask 077
BOOTSTRAP="$(mktemp "${TMPDIR:-/tmp}/lore-bootstrap.XXXXXXXX")"
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  service-account add --client-id "<CLIENT_ID>" --name "<DISPLAY_NAME>" \
  --group "<GROUP>" > "$BOOTSTRAP"
```

command が成功したことを確認し、安全な方法で三列目の secret を CI credential store に登録する。
user ID は権限の確認に使う。account 作成と group 所属は一括確定される。secret や file の内容をログに表示しない。登録と login 確認後、
組織の手順で一時 file を削除する。失敗時も secret の露出を避けて原因を調査する。

続けて [authctl の group / CIDR / grant 手順](authctl.md#4-group-と-runner-の-cidr) の
CIDR と grant を設定する。group と membership の追加は不要。
grant 判定が `allow` であることと、実際の runner から login できることは別々に確認する。
既存 runner の CIDR を消さず、新 runner に必要な CIDR を追加する。

## 3. gRPC proxy と certificate

nginx の gRPC location で、trusted loopback proxy が実際の接続元を bridge に渡す。
構築例に次が入っていること、外部 client が任意の forwarded address を偽装できないことを確認する。

```nginx
grpc_set_header x-lore-client-ip $remote_addr;
```

変更した場合は `nginx -t` を通してから reload する。手前に別 proxy がある場合、実際に bridge へ
伝わる IP を確認する。runner の実行 account が bridge certificate を信頼できるようにし、
Windows service account では必要に応じて管理者が Local Machine trust store に登録する。
[TLS の確認と切り分け](tls-troubleshooting.md) に従い fingerprint を照合する。

## 4. CI job で login と clone

credential store から job に `LORE_CLIENT_ID`、`LORE_CLIENT_SECRET` を安全に渡し、CLI path、
endpoint と repository は環境に合わせる。secret を log に表示しない設定にする。以下は PowerShell
での login / clone 例である。`--auth-url` は Lore Server ではなく **bridge gRPC endpoint** を指定する。
clone 先が既に存在する場合は別 path を選び、自動削除・上書きしない。

```powershell
$ErrorActionPreference = 'Stop'
$clonePath = "C:\Path\To\NewClone"
if (Test-Path -LiteralPath $clonePath) { throw "Clone destination already exists: $clonePath" }
$tokenStoreRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("lore-ci-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tokenStoreRoot | Out-Null
$env:LORE_AUTH_PATH = Join-Path $tokenStoreRoot 'auth'
$env:LORE_GLOBAL_PATH = Join-Path $tokenStoreRoot 'global'
try {
    & $env:LORE_CLI auth login `
      --token-type service-account `
      --token "${env:LORE_CLIENT_ID}:$env:LORE_CLIENT_SECRET" `
      --auth-url "https://<SERVER_HOST>:8081" `
      "lore://<SERVER_HOST>:41337"
    if ($LASTEXITCODE -ne 0) { throw "Lore login failed: $LASTEXITCODE" }

    & $env:LORE_CLI clone `
      "lore://<SERVER_HOST>:41337/<REPOSITORY>" $clonePath --no-pager
    if ($LASTEXITCODE -ne 0) { throw "Lore clone failed: $LASTEXITCODE" }
    if (-not (Test-Path -LiteralPath (Join-Path $clonePath '.lore'))) {
        throw "Lore clone metadata was not created: $clonePath"
    }
}
finally {
    Remove-Item -LiteralPath $tokenStoreRoot -Recurse -Force
    Remove-Item Env:\LORE_AUTH_PATH, Env:\LORE_GLOBAL_PATH
}
```

CLI 引数に credential が渡るため、同一 runner 上の process inspection や CI の command echo
で漏れないよう runner を分離し、アクセス権・ログ出力を制限する。clone / push に bootstrap
secret を渡さない。例は job ごとに token store を隔離し、自分が作成した一時領域だけを削除する。
temporary directory のアクセス権を制限し、job の異常終了時の残存ファイルも管理する。login と clone を確認し、
writer の試験が必要なら専用 repository または承認済み branch で commit / push を確認する。

## 5. secret rotation

`service-account rotate` の help と出力の安全な受け渡し方法を確認し、停止時間を調整する。
旧 secret は rotation と同時に無効になる実装を前提に、全 CI credential store を更新してから
各 runner の login / clone を検証する。漏えい時も同様に速やかに rotate し、影響を調査する。
