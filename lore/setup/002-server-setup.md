# Lore Server 構築手順

Ubuntu host に Lore Server を配置し、構築済みの `lore-auth-bridge` と接続する。
[`work/server-215.md`](../work/server-215.md) を基に一般化した手順である。元の実機は
Ubuntu 26.04 LTS / x86_64 だが、この一般化した手順自体は別環境で通し検証していない。

> [!WARNING]
> 新規構築用である。既存の store、設定、certificate を初期化・上書きしない。

## 0. 前提条件

先に [lore-auth-bridge 構築手順](001-auth-bridge-setup.md) の手順 9 までを実施し、
bridge と nginx が同じ host で稼働し、health / JWKS が正常であることを確認する。
その手順で作成する service user `lore`、`/opt/lore`、`/datadrive/lore`、
certificate と Rust toolchain を利用する。

以下の `<SERVER_HOST>` は bridge 側と同じ DNS 名または IPv4 address、
`<LORE_REVISION>` は使用する bridge と互換性を確認した Lore revision に置き換える。
設定例の port は `41337/tcp`・`41337/udp` と `41339/tcp`。利用者 network のみに公開する。
別 host に配置する場合は JWKS、certificate、systemd の依存関係を別途設計する。

`/datadrive` が意図した永続 storage として mount されていることを確認し、未確認なら中止する。

```bash
findmnt --mountpoint /datadrive
```

## 1. Lore の build と配置

実機では fork を利用した。TLS gRPC 対応を含み bridge と互換性のある revision を選ぶ。

```bash
source "$HOME/.cargo/env"
git clone https://github.com/radicalgrimoire/lore.git "$HOME/src/lore"
cd "$HOME/src/lore"
git checkout --detach <LORE_REVISION>
git rev-parse HEAD
cargo build --release -p lore-client --bin lore -p lore-server --bin loreserver

sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/lore" /opt/lore/bin/lore
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/loreserver" /opt/lore/bin/loreserver
/opt/lore/bin/lore --version
/opt/lore/bin/loreserver --version
```

build した commit hash と変更の有無を運用記録に残す。既存環境の動作確認済み binary を使う
場合は配布元、revision、checksum、license、client/server 互換性を確認する。DB、store、
secret や鍵を新環境へコピーしない。

## 2. directory の作成

既存 directory がある場合、内容と影響を確認してから permission を変更する。

```bash
sudo install -d -o root -g lore -m 0750 /opt/lore/config/lore-server
sudo install -d -o lore -g lore -m 0750 /datadrive/lore/store
```

## 3. Lore Server 設定

`/opt/lore/config/lore-server/production.toml` を作成する。client に返す `auth_url` には
client から到達可能な public gRPC endpoint を設定する。loopback address を指定すると、client
自身の loopback に接続して失敗する。JWT issuer と audience は bridge と一致させる。
`auth_url` は bridge の gRPC TLS endpoint、`server.auth.jwk.endpoint` は HTTP の JWKS
endpoint であり、互いに置き換えられない。audience は実際の remote host と `lore-service`
を含める構成を、使用する revision で確認する。配布形態によっては environment TOML に
加え `default.toml` が必要である。

```toml
[environment.endpoint]
auth_url = "https://<SERVER_HOST>:8081"

[server.quic.certificate]
cert_file = "/opt/lore/certs/lore-server.crt"
pkey_file = "/opt/lore/certs/lore-server.key"

[server.auth]
jwt_issuer = "https://<SERVER_HOST>:8080"
jwt_audience = ["lore-service", "<SERVER_HOST>"]
identity_claim = "preferred_username"

[server.auth.jwk]
endpoint = "http://127.0.0.1:18080/.well-known/jwks.json"

[immutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[mutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10
```

`identity_claim` は revision の Creator 表示に用い、認証・認可用の `sub` とは区別する。
古い revision の Creator はこの設定で書き換わらない。

旧 bridge 文書の対象 revision は起動時に JWKS と JWT 検証を初期化する。bridge の
issuer、audience、署名鍵、JWKS または auth endpoint の変更時は bridge と Lore Server の
再起動要否を確認し、認証と repository 操作まで検証する。

```bash
sudo chown root:lore /opt/lore/config/lore-server/production.toml
sudo chmod 0640 /opt/lore/config/lore-server/production.toml
```

## 4. systemd と起動

`/etc/systemd/system/loreserver.service`:

```ini
[Unit]
Description=Lore server
After=network-online.target lore-auth.service
Wants=network-online.target
RequiresMountsFor=/datadrive

[Service]
Type=simple
User=lore
Group=lore
WorkingDirectory=/opt/lore
Environment=SSL_CERT_FILE=/opt/lore/certs/lore-server.crt
ExecStart=/opt/lore/bin/loreserver --config /opt/lore/config/lore-server --env production
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/datadrive/lore/store

[Install]
WantedBy=multi-user.target
```

`RequiresMountsFor` は mount dependency を設定するが、意図した device が mount されているかの
確認の代わりにはならない。service user が certificate を読め、store に書けることを確認する。
各 `test` の成功を確認してから service を起動する。

```bash
sudo -u lore test -r /opt/lore/certs/lore-server.key
sudo -u lore test -w /datadrive/lore/store
sudo systemctl daemon-reload
sudo systemctl enable --now loreserver
```

## 5. server の受入確認

```bash
systemctl is-enabled lore-auth nginx loreserver
systemctl is-active lore-auth nginx loreserver
sudo ss -lntup | grep -E ':(41337|41339)\b'
sudo journalctl -u loreserver -n 100 --no-pager
```

3 service が `enabled` / `active`、Lore の TCP・UDP listener が想定どおりであることを確認する。
HTTP health の成功だけでは gRPC の動作や client の trust は確認できない。

## 6. Windows client の初回接続

[Windows CLI インストール手順](003-windows-cli-setup.md) に従い、互換性を確認した client の配置、
certificate の信頼、Entra login と clone を確認する。ログインする利用者は先に
[bridge の利用者登録](001-auth-bridge-setup.md#10-利用者登録と-repository-へのアクセス) で
identity を登録する。接続に失敗した場合は [TLS の確認と切り分け](../operations/001-tls-troubleshooting.md) を参照する。

## 導入後

bridge の [利用者登録](001-auth-bridge-setup.md#10-利用者登録と-repository-へのアクセス) で
identity binding と repository grant を設定してから、実 client で login と clone を確認する。
CI の login や writer 操作は別途実行して確認する。DB、JWT signing key、Lore store、設定を
同じ時点の recovery set として backup し、復元試験を行う。実機での作業は
[作業記録](../work/) を参照する。
