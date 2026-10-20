# 172.20.12.215 Lore Server 導入記録

この文書は、Ubuntu 26.04 LTS ホスト `172.20.12.215` に Lore Server と
`lore-auth-bridge` を導入し、Microsoft Entra ID による認証を有効化した記録である。

対象はサーバー導入、サービス起動、Windows クライアントからの初回ログインまでとする。
ユーザーへの repository 権限付与、repository 作成、バックアップ運用は扱わない。

> [!WARNING]
> client secret、JWT 署名鍵、TLS 秘密鍵、SQLite database、Lore repository store は
> 本文やソース管理へ保存しない。以下のコマンド中の `<...>` は運用環境の値に置換する。

## 最終構成

- OS: Ubuntu 26.04 LTS / x86_64
- Lore Server IP: `172.20.12.215`
- Lore のバイナリ・設定・証明書: `/opt/lore`
- Lore 永続 store: `/datadrive/lore/store`
- auth bridge の DB・JWT 鍵: `/datadrive/lore/auth`
- Entra client secret: `/etc/lore/secrets/entra-client-secret`
- サービス実行ユーザー: `mgs`
- Lore remote: `lore://172.20.12.215:41337`
- auth HTTP / JWKS: `https://172.20.12.215:8080`
- auth gRPC: `https://172.20.12.215:8081`

`/datadrive` はローカル block storage 上の ext4 として mount されていることを確認した。
SQLite database を NFS/SMB/object storage に置かない。

公開するポートは `41337/tcp` と `41337/udp`（Lore client）、`41339/tcp`（Lore HTTP）、
`8080/tcp`（auth bridge HTTP、JWKS、Entra redirect）、`8081/tcp`（auth bridge gRPC）である。
ネットワーク境界で社内ネットワークだけから到達できるように制限する。この導入では UFW は
有効化しない。

## 1. 前提パッケージと Rust toolchain

`mgs` でログインし、管理操作だけ `sudo` を使う。

```bash
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential ca-certificates cmake curl git libssl-dev nginx openssl \
  pkg-config rsync

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
rustc --version
cargo --version
```

## 2. 運用ディレクトリ

```bash
sudo install -d -o mgs -g mgs -m 0755 \
  /opt/lore /opt/lore/bin /opt/lore/config /opt/lore/certs
sudo install -d -o mgs -g mgs -m 0750 \
  /datadrive/lore /datadrive/lore/store \
  /datadrive/lore/auth /datadrive/lore/auth/data /datadrive/lore/auth/keys
sudo install -d -o root -g mgs -m 0750 /etc/lore /etc/lore/secrets
install -d -m 0755 "$HOME/src"
```

## 3. Lore と auth bridge の build

導入時点の upstream `main` をサーバー上へ shallow clone し、release build を行った。

```bash
source "$HOME/.cargo/env"

git clone --depth=1 --branch main https://github.com/radicalgrimoire/lore.git \
  "$HOME/src/lore"
git clone --depth=1 --branch main \
  https://github.com/radicalgrimoire/lore-auth-bridge.git \
  "$HOME/src/lore-auth-bridge"

cd "$HOME/src/lore"
cargo build --release \
  -p lore-client --bin lore \
  -p lore-server --bin loreserver

cd "$HOME/src/lore-auth-bridge"
cargo build --release -p lore-auth-server -p lore-authctl
```

auth bridge は Entra の callback を GET query callback として受けるため、OIDC authorization
request に `response_mode=query` を含めた build を使う。使用する bridge revisionにこの指定が
ない場合は、`Provider::begin_auth` の authorization request に次を追加してから build する。

```rust
auth_request = auth_request.add_extra_param("response_mode", "query");
```

auth bridge のバイナリを配置する。

```bash
sudo install -o mgs -g mgs -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-auth-server" \
  /opt/lore/bin/lore-auth-server
sudo install -o mgs -g mgs -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-authctl" \
  /opt/lore/bin/lore-authctl
```

### 3.1 既存稼働環境との Lore binary 互換

`172.20.12.193` は既存の正式運用 Lore Server である。
215 では同じ client/server wire behavior を使うため、**Lore と loreserver のみ**を
193 の動作確認済み binary に置換した。auth bridge、Entra application、DB、鍵、repository
store は複製しない。

置換前に 215 側の binary と設定を archive する。

```bash
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="/opt/lore/archive/$STAMP"
sudo install -d -o root -g root -m 0700 "$ARCHIVE/bin" "$ARCHIVE/nginx" "$ARCHIVE/systemd"
sudo cp -p /opt/lore/bin/lore /opt/lore/bin/loreserver "$ARCHIVE/bin/"
sudo cp -p /etc/nginx/sites-available/lore-auth "$ARCHIVE/nginx/lore-auth"
sudo cp -p /etc/systemd/system/loreserver.service "$ARCHIVE/systemd/"
```

管理端末から、SSH host key を確認済みの状態で 193 の binary を staging directory へ転送する。

```bash
ssh mgs@172.20.12.215 'install -d -m 0755 /home/mgs/lore-transfer'
scp -3 \
  mgs@172.20.12.193:/datadrive2/lore/bin/lore \
  mgs@172.20.12.215:/home/mgs/lore-transfer/lore
scp -3 \
  mgs@172.20.12.193:/datadrive2/lore/bin/loreserver \
  mgs@172.20.12.215:/home/mgs/lore-transfer/loreserver
```

193 と staging directory の SHA-256 が一致することを確認してから配置する。

```bash
sha256sum /home/mgs/lore-transfer/lore /home/mgs/lore-transfer/loreserver
sudo install -o mgs -g mgs -m 0755 /home/mgs/lore-transfer/lore /opt/lore/bin/lore
sudo install -o mgs -g mgs -m 0755 \
  /home/mgs/lore-transfer/loreserver /opt/lore/bin/loreserver
```

## 4. 自己署名サーバー証明書

Windows クライアントを正式運用環境と同じ方式で接続するため、独立した CA ではなく、
`CA:FALSE` の自己署名サーバー証明書を使う。証明書には server IP と loopback を SAN として
含める。

```bash
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj "/CN=172.20.12.215" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "subjectAltName=IP:172.20.12.215,DNS:localhost,IP:127.0.0.1" \
  -keyout "$WORKDIR/lore-server.key" \
  -out "$WORKDIR/lore-server.crt"

sudo install -o mgs -g mgs -m 0644 \
  "$WORKDIR/lore-server.crt" /opt/lore/certs/lore-server.crt
sudo install -o mgs -g mgs -m 0600 \
  "$WORKDIR/lore-server.key" /opt/lore/certs/lore-server.key

openssl x509 -in /opt/lore/certs/lore-server.crt -noout \
  -subject -issuer -dates -ext subjectAltName
```

## 5. Microsoft Entra ID application

Entra 管理者に Web application を作成してもらう。Supported account types は
「この組織ディレクトリ内のアカウントのみ」とする。Redirect URI は
`https://172.20.12.215:8080/auth/entra/callback`、API permissions は OpenID Connect の
`openid`、`profile`、`email` を設定する。

Application (client) ID は bridge 設定へ書く。client secret の **Value** は chat、shell history、
リポジトリへ残さず、root が所有するファイルへ保存する。

```bash
sudoedit /etc/lore/secrets/entra-client-secret
sudo chown root:mgs /etc/lore/secrets/entra-client-secret
sudo chmod 640 /etc/lore/secrets/entra-client-secret
```

## 6. auth bridge 設定

`/opt/lore/config/lore-auth.yaml` を作成する。`<...>` の値は実環境の値を使用する。

```yaml
server:
  listen: "127.0.0.1:18080"
  grpc_listen: "127.0.0.1:18081"
  grpc_tls_cert_file: "/opt/lore/certs/lore-server.crt"
  grpc_tls_key_file: "/opt/lore/certs/lore-server.key"
  public_base_url: "https://172.20.12.215:8080"

identity_providers:
  default: entra
  providers:
    entra:
      type: oidc
      profile: entra
      display_name: "Microsoft Entra ID"
      issuer: "https://login.microsoftonline.com/<tenant-id>/v2.0"
      client_id: "<application-client-id>"
      client_secret_file: "/etc/lore/secrets/entra-client-secret"
      redirect_url: "https://172.20.12.215:8080/auth/entra/callback"
      scopes: [openid, email, profile]
      pkce: required
      subject:
        strategy: entra_oid_tid
        required_tid: "<tenant-id>"
      trust:
        email_binding: verified_email_invitation
        allowed_email_domains: ["gamestudio.co.jp"]

database:
  path: "/datadrive/lore/auth/data/lore-auth.sqlite3"

authz:
  backend: rebac

jwt:
  issuer: "https://172.20.12.215:8080"
  audience: ["lore-service", "172.20.12.215"]
  ttl_seconds: 3600
  signing_key_dir: "/datadrive/lore/auth/keys"
  active_kid: "lore-entra-01"

lore:
  default_remote_url: "lore://172.20.12.215:41337"
  auth_url: "https://172.20.12.215:8081"

admin:
  admin_emails: ["<initial-admin-email>"]

security:
  admin_allowed_peer_cidrs: ["127.0.0.1/32"]
  rebac_allowed_peer_cidrs: ["127.0.0.1/32"]
```

```bash
sudo chown mgs:mgs /opt/lore/config/lore-auth.yaml
sudo chmod 0640 /opt/lore/config/lore-auth.yaml
```

## 7. Lore Server 設定

クライアントへ返す `auth_url` は public gRPC endpoint を指定する。
`127.0.0.1:18081` を指定すると、Windows Lore CLI は自分自身の loopback に接続して失敗する。

`/opt/lore/config/lore-server/production.toml`:

```toml
[environment.endpoint]
auth_url = "https://172.20.12.215:8081"

[server.quic.certificate]
cert_file = "/opt/lore/certs/lore-server.crt"
pkey_file = "/opt/lore/certs/lore-server.key"

[server.auth]
jwt_issuer = "https://172.20.12.215:8080"
jwt_audience = ["lore-service", "172.20.12.215"]
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

`identity_claim = "preferred_username"` により、以後の revision history の Creator には
内部 UUID ではなく auth bridge が発行するメールアドレスを記録する。認証と認可に使う JWT
subject (`sub`) は内部 ID のまま維持されるため、この設定は commit author の表示・監査用途だけを
読みやすくする。設定前に作成した revision の Creator は変更されない。

```bash
sudo install -d -o mgs -g mgs -m 0750 /opt/lore/config/lore-server
sudo chown mgs:mgs /opt/lore/config/lore-server/production.toml
sudo chmod 0640 /opt/lore/config/lore-server/production.toml
```

## 8. Nginx 設定

`/etc/nginx/sites-available/lore-auth`:

```nginx
server {
    listen 8080 ssl;
    server_name 172.20.12.215;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 8081 ssl;
    http2 on;
    server_name 172.20.12.215;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;

    location ^~ /ucs.auth.RebacApi/ {
        allow 127.0.0.1;
        allow 172.20.12.215;
        deny all;
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }

    location / {
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }
}
```

`grpc_ssl_verify off` は、Nginx から loopback の自己署名 gRPC certificate への upstream
接続だけに適用される。Windows client から Nginx への TLS 検証を無効にする設定ではない。

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sfn /etc/nginx/sites-available/lore-auth /etc/nginx/sites-enabled/lore-auth
sudo nginx -t
```

## 9. systemd

`/etc/systemd/system/lore-auth.service`:

```ini
[Unit]
Description=Lore authentication bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=mgs
Group=mgs
WorkingDirectory=/opt/lore
ExecStart=/opt/lore/bin/lore-auth-server --config /opt/lore/config/lore-auth.yaml
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/datadrive/lore/auth

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/loreserver.service`:

```ini
[Unit]
Description=Lore server
After=network-online.target lore-auth.service
Wants=network-online.target

[Service]
Type=simple
User=mgs
Group=mgs
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

bridge の SQLite DB と JWT signing key を初期化してから有効化する。

```bash
/opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml init-db
/opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  signing-key generate --kid lore-entra-01

sudo systemctl daemon-reload
sudo systemctl enable --now lore-auth nginx loreserver
```

## 10. サーバー確認

```bash
systemctl is-enabled lore-auth nginx loreserver
systemctl is-active lore-auth nginx loreserver

curl -fk https://172.20.12.215:8080/healthz
curl -fk https://172.20.12.215:8080/.well-known/jwks.json

sudo ss -lntup | grep -E ':(41337|41339|8080|8081)\b'
sudo nginx -t
```

期待値は、3 service が `enabled` かつ `active`、health endpoint が `ok`、
Lore が `41337/tcp`・`41337/udp`・`41339/tcp`、Nginx が `8080/tcp`・`8081/tcp` を
listen していること。

## 11. Windows クライアントの初回接続

Windows client へ自己署名 **サーバー証明書**を配布し、Current User の Trusted Root
Certification Authorities へ登録する。

```powershell
scp mgs@172.20.12.215:/opt/lore/certs/lore-server.crt `
  "D:\Projects\Watch\lore-server.crt"

Import-Certificate `
  -FilePath "D:\Projects\Watch\lore-server.crt" `
  -CertStoreLocation Cert:\CurrentUser\Root
```

同じ PowerShell session で certificate file を明示して Lore CLI をログインさせる。

```powershell
$env:SSL_CERT_FILE = "D:\Projects\Watch\lore-server.crt"
lore auth login lore://172.20.12.215:41337
```

ブラウザで Entra ID へログインする。callback URL を直接開いてはいけない。
ログイン開始時に生成される `state` と、Entra が返す authorization code が必要である。

## 導入後に別途必要なこと

- SQLite DB、JWT signing key、Lore store を含むバックアップ設計と復元試験
- Entra client secret の期限管理と更新手順
- 証明書の有効期限前更新と Windows client への再配布
- `lore-authctl` によるユーザー招待、identity bind、repository grant
- ネットワーク境界で公開ポートを社内 CIDR に限定していることの確認
