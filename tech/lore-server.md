# LORE Server の構築・運用

社内テスト用 Lore Server `172.20.12.193` の構築、永続 store の設定、および
release 更新時の手順をまとめる。

CLI のインストールと repository 操作は [LORE CLI の利用](./lore-cli.md) を参照する。
server binary の release 配置と更新は [LORE Server の更新](./lore-server-update.md) を参照する。
Entra account と repository grant の管理は
[LORE Server のアカウント管理](./lore-server-account.md) を参照する。

## 現在の構成

| 項目 | 値 |
| --- | --- |
| ホスト | `172.20.12.193` |
| Lore Server systemd unit | `lore.service` |
| 認証 bridge systemd unit | `lore-auth-bridge.service` |
| Lore Server binary | `/datadrive/lore/bin/loreserver` |
| Lore CLI binary | `/datadrive/lore/bin/lore` |
| Lore config directory | `/datadrive/lore/config` |
| 永続 Lore store | `/datadrive/lore/data/store` |
| QUIC certificate | `/datadrive/lore/certs/cert.pem` |
| QUIC private key | `/datadrive/lore/certs/key.pem` |
| bridge config | `/home/mgs/lore-auth/lore-auth.yaml` |
| bridge management CLI | `/home/mgs/lore-auth/bin/lore-authctl` |
| Entra onboarding script | `/home/mgs/lore-auth/bin/onboard-entra-user.sh` |

Lore の公開 endpoint は `lore://172.20.12.193:41337` である。

## 絶対に `/tmp` を store に使わない

`loreserver` は local store path が未設定の場合、既定で `/tmp/lore-server` を使う。
`/tmp` は OS の cleanup や再起動で削除されるため、repository data が失われる。

実際に `local.toml` が無い状態では、稼働中 process が削除済み
`/tmp/lore-server/... (deleted)` file descriptor だけを保持する危険な状態になった。
この状態で service を停止すると、残っている repository data も失われる。

本番・テストを問わず、immutable store と mutable store の両方に明示的な永続パスを
設定する。

## 初期構築

### 1. 必要な directory を作成する

以下は `mgs` で service を動かす構成である。

```bash
ssh mgs@172.20.12.193

sudo install -d -o mgs -g mgs -m 0750 \
  /datadrive/lore/data/store \
  /datadrive/lore/certs
sudo install -d -o root -g root -m 0755 \
  /datadrive/lore/bin \
  /datadrive/lore/config \
  /datadrive/lore/releases
```

### 2. 永続 QUIC 証明書を作成する

これは Lore の QUIC endpoint 用であり、認証 bridge の HTTPS certificate とは別物である。
自己署名 certificate を使う場合でも、毎回作り直さず永続パスに置く。

```bash
sudo openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /datadrive/lore/certs/key.pem \
  -out /datadrive/lore/certs/cert.pem \
  -days 365 \
  -subj "/CN=172.20.12.193" \
  -addext "subjectAltName=IP:172.20.12.193,DNS:localhost,IP:127.0.0.1"

sudo chown mgs:mgs /datadrive/lore/certs/cert.pem /datadrive/lore/certs/key.pem
sudo chmod 0644 /datadrive/lore/certs/cert.pem
sudo chmod 0600 /datadrive/lore/certs/key.pem
```

クライアントで certificate 検証を厳密に行う構成へ移行する場合は、社内 CA または
公開 CA の certificate に置き換える。IP address ではなく DNS 名を使う場合は、
certificate SAN、Lore remote URL、Entra callback URL を同じ DNS 名に統一する。

### 3. 永続 store 設定を作成する

`lore.service` は `LORE_ENV=dev` と
`LORE_CONFIG_PATH=/datadrive/lore/config` を設定している。
`local.toml` は environment overlay の後に読み込まれるため、site 固有設定はここへ置く。

`/datadrive/lore/config/local.toml`:

```toml
[server.quic.certificate]
cert_file = "/datadrive/lore/certs/cert.pem"
pkey_file = "/datadrive/lore/certs/key.pem"

[immutable_store.local]
path = "/datadrive/lore/data/store"
flush_delay_seconds = 10

[mutable_store.local]
path = "/datadrive/lore/data/store"
flush_delay_seconds = 10
```

設定後に起動すると、store directory には少なくとも次が作成される。

```text
/datadrive/lore/data/store/
├── immutable/
└── mutable/
```

### 4. systemd unit を確認する

`LORE_ENV` は environment 固有の TOML を選ぶ環境変数である。この host では
`LORE_ENV=dev` のため `dev.toml` を読み込む。`local.toml` は environment 名に
関係なく、config directory に存在すれば常に最後の TOML layer として読み込まれる。

設定の優先順は以下の通りで、後に適用される同一キーが前の値を上書きする。

```text
binary 内蔵 default.toml
  → <LORE_ENV>.toml
    → local.toml
      → LORE__... environment variables
```

したがって `hoge.toml` は、`LORE_ENV=hoge` に設定した場合だけ読み込まれる。
`local.toml` は `LORE_ENV` が `dev`、`hoge`、その他どの値でも存在する限り読み込まれる。
環境共通の設定は `<LORE_ENV>.toml`、host 固有の store path や certificate path は
`local.toml` に置く。`LORE__...` environment variable は最優先の緊急 override とし、
常設設定には使わない。

`/etc/systemd/system/lore.service` は次の設定を維持する。

```ini
[Unit]
Description=Lore Server
After=network.target

[Service]
Type=simple
User=mgs
Group=mgs
Environment=RUST_LOG=info
Environment=LORE_ENV=dev
Environment=LORE_CONFIG_PATH=/datadrive/lore/config
ExecStart=/datadrive/lore/bin/loreserver
WorkingDirectory=/datadrive/lore
LimitNOFILE=1048576
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

auth bridge の certificate を Lore Server が検証できるよう、drop-in
`/etc/systemd/system/lore.service.d/lore-auth-bridge.conf` に次を設定する。

```ini
[Service]
Environment=SSL_CERT_FILE=/home/mgs/lore-auth/grpc/tls.crt
```

unit や drop-in を変更した場合は以下を実行する。

```bash
sudo systemctl daemon-reload
sudo systemctl restart lore
```

## 更新

release archive の取得、backup、binary 切り替え、bridge と Lore Server の起動順、
client の受入確認は [Lore Server の更新](./lore-server-update.md) を参照する。

## Git への撤退用バックアップ

Lore の更新履歴を Git に一方向転記し、Lore を継続利用しないと判断した場合に Git
から開発を再開できるようにするスクリプト一式は
[Lore-to-Git backup](../scripts/lore-git-backup/README.md) に置く。これは immutable /
mutable store のバックアップの代替ではない。store backup は Lore deployment を復旧する
ため、Git backup は Lore なしでプロジェクトを再開するための、異なる目的の保険である。

Git backup は毎日 02:00 に未転記の Lore revision を古い順に Git commit へ転記する
構成を想定する。各 Git commit は、Lore の作成者、作成時刻、メッセージ、full revision
signature を記録する。初回実行、Git push、Git だけからの restore test が成功するまでは
timer を有効化しない。

## 障害時の確認

```bash
sudo systemctl status lore lore-auth-bridge --no-pager
sudo journalctl -u lore -n 100 --no-pager
sudo journalctl -u lore-auth-bridge -n 100 --no-pager

curl -fk https://172.20.12.193:8080/healthz
curl -fk https://172.20.12.193:8080/.well-known/jwks.json
sudo ss -lntup | grep -E ':(8080|41337|41339)\b'
```

`identity provider login failed` が出た場合は、bridge の稼働、Entra client ID / secret、
redirect URL、Entra Sign-in logs、client 側の certificate trust を確認する。bridge が
内部状態不整合を起こした疑いがある場合は、`lore-auth-bridge` のみを再起動できる。

```bash
sudo systemctl restart lore-auth-bridge
```
