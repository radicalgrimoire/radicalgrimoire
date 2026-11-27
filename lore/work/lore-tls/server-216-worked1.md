# 1. Lore CLI と Lore Server の構築（TLS 版）

この 1〜4 は新規構築向けの未検証手順。既存の 216 にそのまま再実行しない。
対象 OS は 216 の Ubuntu 26.04。
`/datadrive` は永続ストレージとしてマウント済みとする。
CA、証明書、クライアントの信頼設定は社内の運用に従う。
TLS 版の制約と設定例は同じフォルダの README.md を参照。

## 環境確認とビルド

```bash
cat /etc/os-release
uname -m
id
df -h /
command -v git cargo rustc lore loreserver
systemctl list-unit-files 'loreserver.service' --no-pager

sudo apt-get update
sudo apt-get install -y build-essential ca-certificates cmake curl git libssl-dev openssl pkg-config
```

以降は `mgs` などの非 root ユーザーで実行する。Rust 未導入の場合：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
rustc --version
cargo --version

mkdir -p "$HOME/src"
git clone --branch develop --single-branch \
  https://github.com/radicalgrimoire/lore.git \
  "$HOME/src/lore"
cd "$HOME/src/lore"
git branch --show-current
git rev-parse HEAD

cargo build --release --locked \
  -p lore-client --bin lore \
  -p lore-server --bin loreserver

target/release/lore --version
target/release/loreserver --version
sha256sum target/release/lore target/release/loreserver
```

ブランチと Rust の最新版を取得するため、ビルド時点で同じバージョンとは限らない。

## インストールと証明書

```bash
sudo install -o root -g root -m 0755 target/release/lore /usr/local/bin/lore
sudo install -d -o root -g root -m 0755 /datadrive/lore /datadrive/lore/bin
sudo install -o root -g root -m 0755 \
  target/release/loreserver /datadrive/lore/bin/loreserver
sudo install -d -o mgs -g mgs -m 0750 \
  /datadrive/lore/config /datadrive/lore/certs /datadrive/lore/store

lore --version
/datadrive/lore/bin/loreserver --version
```

社内 CA が発行した証明書を用意し、管理者の手順に従って配置する。
この手順は証明書を発行しない。既存の鍵や証明書を上書きしない。

- `/datadrive/lore/certs/lore-server.crt`：サーバー証明書と必要な中間証明書
- `/datadrive/lore/certs/lore-server.key`：秘密鍵。`mgs` と Nginx が読めるよう権限を制限
- `/datadrive/lore/certs/lore-ca.crt`：検証に使う CA 証明書

SAN に `IP:172.20.11.216`、`IP:127.0.0.1`、`DNS:localhost` を含める。
CA 証明書を Ubuntu のシステム CA bundle に登録し、公開 CA も引き続き信頼できる
状態にする。配布するのは CA 証明書であり、CA 秘密鍵ではない。
証明書の取得・配置・CA 登録が済むまで次へ進まない。

```bash
openssl x509 -in /datadrive/lore/certs/lore-server.crt \
  -noout -subject -issuer -dates -ext subjectAltName
ls -l /datadrive/lore/certs
```

## Lore Server の初期設定

初期確認は localhost で行う。設定例全体は同じフォルダの `gspcd581.toml` を参照。
新規ファイルに以下を設定する。既存の設定を上書きしない。

```bash
vim /datadrive/lore/config/gspcd581.toml
```

```toml
[server.quic.certificate]
cert_file = "/datadrive/lore/certs/lore-server.crt"
pkey_file = "/datadrive/lore/certs/lore-server.key"

[server.grpc.certificate]
cert_file = "/datadrive/lore/certs/lore-server.crt"
pkey_file = "/datadrive/lore/certs/lore-server.key"

[immutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[mutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[server.quic]
host = "127.0.0.1"

[server.grpc]
host = "127.0.0.1"

[server.http]
host = "127.0.0.1"
```

サービス定義は平文版の `loreserver.md` を参考にする。ただし、証明書の信頼先は
worked4 で設定するシステム CA bundle を使い、自己署名証明書用の
`SSL_CERT_FILE=/datadrive/lore/certs/lore-server.crt` は設定しない。

```bash
sudo vim /etc/systemd/system/loreserver.service
sudo systemctl daemon-reload
sudo systemctl start loreserver
systemctl status loreserver --no-pager -l
ss -lntu '( sport = :41337 or sport = :41339 )'
curl --noproxy '*' -i --max-time 10 http://127.0.0.1:41339/health_check
```
