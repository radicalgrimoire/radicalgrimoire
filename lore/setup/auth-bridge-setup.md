# lore-auth-bridge 構築手順

Ubuntu host に `lore-auth-bridge` と nginx を配置し、Microsoft Entra ID を接続する。
実機記録 [`work/server-215.md`](../work/server-215.md) を基に一般化した手順であり、
この手順自体は別環境で通し検証していない。以下は Lore Server と同一 host に配置する例。
使用する bridge revision の設定 schema と Lore との互換性を確認する。

> [!WARNING]
> 新規構築用である。既存の DB、鍵、certificate、設定を初期化・上書きしない。
> client secret、JWT signing key、TLS private key、SQLite database を source control、
> chat、shell history に残さない。

## 0. 事前に決める値と構成

以下の `<...>` を実環境の値に置き換える。設定ファイル内の `<SERVER_HOST>` はシェル変数
ではないため、ファイルを作成するときに直接置き換える。

| 値 | 用途 |
| --- | --- |
| `<SERVER_HOST>` | client から接続できる server の DNS 名または IPv4 address。URL、JWT、certificate SAN で一致させる |
| `<SERVER_IP>` | Lore Server から nginx へ接続するときの送信元 IPv4 address。ReBAC API の許可に使う |
| `<TENANT_ID>` | Entra tenant ID |
| `<CLIENT_ID>` | Entra application の client ID |
| `<ALLOWED_EMAIL_DOMAIN>` | 対象の email domain |
| `<ADMIN_EMAIL>` | bridge の初期管理者 email |
| `<BRIDGE_REVISION>` | Lore と互換性を確認した bridge の source revision、tag または commit |

以下の例では、service user を `lore`、binary と設定を `/opt/lore`、永続データを
`/datadrive/lore` に置く。異なる path を使う場合は、設定、systemd、permission のすべてを
整合させる。`/datadrive` はあらかじめ永続的な local block storage として mount する。
SQLite database は NFS、SMB、object storage に置かない。mount が利用できない状態で
ローカルの空 directory に store を作らないこと。

| 接続先 | 用途 |
| --- | --- |
| `lore://<SERVER_HOST>:41337` | Lore client |
| `https://<SERVER_HOST>:8080` | bridge HTTP、Entra callback、JWKS |
| `https://<SERVER_HOST>:8081` | bridge gRPC |
| `127.0.0.1:18080` / `127.0.0.1:18081` | nginx から bridge への内部接続 |

`41337/tcp`・`41337/udp`、`41339/tcp`、`8080/tcp`、`8081/tcp` を network boundary で
許可し、利用者の network だけに制限する。bridge の内部 port は外部に公開しない。
DNS 名を使う場合は server と client の双方から名前解決できること。

## 1. 前提 package と build 環境

sudo を使える管理 user で実行する。Rust toolchain と source はその管理 user の home に置き、
service user の home には置かない。

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

## 2. service user と directory

専用 user がなければ作成する。同名 user が既に存在する場合は、所有者や用途を確認してから
使用する。既存の directory を使う場合は、permission を変更する前に内容と影響を確認する。

```bash
sudo useradd --system --user-group --home-dir /nonexistent \
  --shell /usr/sbin/nologin lore
```

次を実行し、表示された mount と device が意図した永続 storage であることを確認する。
`/datadrive` 自体が mount point でない場合や、想定と違う場合は中止する。

```bash
findmnt --mountpoint /datadrive
```

確認後に directory を作成する。

```bash
sudo install -d -o root -g root -m 0755 \
  /opt/lore /opt/lore/bin
sudo install -d -o root -g lore -m 0750 \
  /opt/lore/config /opt/lore/certs \
  /etc/lore /etc/lore/secrets
sudo install -d -o lore -g lore -m 0750 \
  /datadrive/lore \
  /datadrive/lore/auth /datadrive/lore/auth/data /datadrive/lore/auth/keys
install -d -m 0755 "$HOME/src"
```

## 3. bridge の build・配置

実機では `radicalgrimoire` の fork を利用している。Entra identity binding、callback 対応を
含み、Lore Server と互換性のある revision を選ぶ。最新 `main` が同じ動作をするとは限らない。

```bash
source "$HOME/.cargo/env"
git clone https://github.com/radicalgrimoire/lore-auth-bridge.git \
  "$HOME/src/lore-auth-bridge"
cd "$HOME/src/lore-auth-bridge"
git checkout --detach <BRIDGE_REVISION>
git rev-parse HEAD
cargo build --release -p lore-auth-server -p lore-authctl
```

Entra callback を GET query として受ける revision では、authorization request に
`response_mode=query` が必要である。選択した revision に含まれることを確認し、欠ける場合は
互換性を確認した修正版を使う。build した commit hash と変更の有無を運用記録に残す。

```bash
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-auth-server" \
  /opt/lore/bin/lore-auth-server
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-authctl" /opt/lore/bin/lore-authctl
/opt/lore/bin/lore-authctl --help
```

## 4. TLS certificate の作成

実機では `CA:FALSE` の自己署名 server certificate を client の trust anchor として配布した。
ここも同じ方式の例である。組織の CA を使う場合は適切な server certificate と CA の配布手順に
置き換える。

次の 2 行だけを自環境の値に編集する。IP の例は `SERVER_SAN='IP:192.0.2.10'`、
DNS の例は `SERVER_SAN='DNS:lore.example.com'`。`SERVER_HOST` と SAN は一致させる。

```bash
SERVER_HOST='<SERVER_HOST>'
SERVER_SAN='<IP:address または DNS:hostname>'
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj "/CN=$SERVER_HOST" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "subjectAltName=$SERVER_SAN,DNS:localhost,IP:127.0.0.1" \
  -keyout "$WORKDIR/lore-server.key" \
  -out "$WORKDIR/lore-server.crt"

sudo install -o root -g lore -m 0644 \
  "$WORKDIR/lore-server.crt" /opt/lore/certs/lore-server.crt
sudo install -o root -g lore -m 0640 \
  "$WORKDIR/lore-server.key" /opt/lore/certs/lore-server.key
openssl x509 -in /opt/lore/certs/lore-server.crt -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName
```

subject、SAN、有効期限、fingerprint を確認する。private key は server 外に配布しない。

## 5. Entra application と client secret

Entra 管理者に Web application を作成してもらい、組織内 account に限定する。Web redirect
URI を `https://<SERVER_HOST>:8080/auth/entra/callback` とし、OpenID Connect の
`openid`、`profile`、`email` を設定する。

「Certificates & secrets」で client secret を発行し、**Secret ID ではなく Value** を
安全に保管する。Value は作成時以外には再表示できない。期限と更新担当者を記録し、値は
shell history、command 引数、ログ、chat に残さない。editor の一時ファイルや backup にも注意する。
新規構築時は Value を root 所有 file に保存する。

```bash
sudoedit /etc/lore/secrets/entra-client-secret
sudo chown root:lore /etc/lore/secrets/entra-client-secret
sudo chmod 0640 /etc/lore/secrets/entra-client-secret
```

service user の読み取りを確認し、server 上で Entra の token endpoint に接続して Secret を
検証する。source checkout の path、tenant ID、client ID は実環境に合わせる。Python 3 と
Entra への HTTPS 接続が必要。検証者は secret file を読み取れる必要がある。

```bash
sudo -u lore test -r /etc/lore/secrets/entra-client-secret
sudo bash "$HOME/src/lore-auth-bridge/scripts/verify-entra-client-secret.sh" \
  --tenant-id "<TENANT_ID>" \
  --client-id "<CLIENT_ID>" \
  --secret-file /etc/lore/secrets/entra-client-secret
```

この検証は Microsoft Graph 向け client credentials 要求の結果であり、Entra browser login
全体の成功は保証しない。失敗時は Secret の誤りだけでなく tenant / client ID、app 設定、
権限、ネットワークも確認する。Secret の更新時は新しい Value を別ファイルで検証し、
旧 Secret と復旧手段を確保してから置き換える。bridge は起動時に読み込むため、再起動後に
実際の login と Lore 操作を確認する。旧 Secret は切り替え成功まで失効させない。

## 6. bridge 設定

`/opt/lore/config/lore-auth.yaml` を作成し、すべての `<...>` を置き換える。
以下は実機で使った revision の設定例である。

> [!WARNING]
> この例の `admin_emails` は管理 UI を有効にする。nginx の例には管理画面専用の
> 送信元制限がないため、公開前に [管理 Web UI の設定と操作](../operations/admin-ui.md) に従って
> 管理 endpoint のアクセス制限を確認する。使用しない場合は `admin_emails` を空にする。

```yaml
server:
  listen: "127.0.0.1:18080"
  grpc_listen: "127.0.0.1:18081"
  grpc_tls_cert_file: "/opt/lore/certs/lore-server.crt"
  grpc_tls_key_file: "/opt/lore/certs/lore-server.key"
  public_base_url: "https://<SERVER_HOST>:8080"

identity_providers:
  default: entra
  providers:
    entra:
      type: oidc
      profile: entra
      display_name: "Microsoft Entra ID"
      issuer: "https://login.microsoftonline.com/<TENANT_ID>/v2.0"
      client_id: "<CLIENT_ID>"
      client_secret_file: "/etc/lore/secrets/entra-client-secret"
      redirect_url: "https://<SERVER_HOST>:8080/auth/entra/callback"
      scopes: [openid, email, profile]
      pkce: required
      subject:
        strategy: entra_oid_tid
        required_tid: "<TENANT_ID>"
      trust:
        email_binding: verified_email_invitation
        allowed_email_domains: ["<ALLOWED_EMAIL_DOMAIN>"]

database:
  path: "/datadrive/lore/auth/data/lore-auth.sqlite3"

authz:
  backend: rebac

jwt:
  issuer: "https://<SERVER_HOST>:8080"
  audience: ["lore-service", "<SERVER_HOST>"]
  ttl_seconds: 3600
  signing_key_dir: "/datadrive/lore/auth/keys"
  active_kid: "lore-entra-01"

lore:
  default_remote_url: "lore://<SERVER_HOST>:41337"
  auth_url: "https://<SERVER_HOST>:8081"

admin:
  admin_emails: ["<ADMIN_EMAIL>"]

security:
  admin_allowed_peer_cidrs: ["127.0.0.1/32"]
  rebac_allowed_peer_cidrs: ["127.0.0.1/32"]
```

```bash
sudo chown root:lore /opt/lore/config/lore-auth.yaml
sudo chmod 0640 /opt/lore/config/lore-auth.yaml
```

Entra の email claim が未検証になる tenant では、invitation だけに依存せず、管理者が
`<tenant-id>:<object-id>` を user に bind する。[利用者登録](#10-利用者登録と-repository-へのアクセス)
を参照する。

## 7. nginx 設定

`/etc/nginx/sites-available/lore-auth` を作成し、`<SERVER_HOST>` と `<SERVER_IP>` を
置き換える。`<SERVER_IP>` には Lore Server が nginx に接続するときの実際の送信元 IP を使う。
ReBAC API は必要な caller だけに許可する。

```nginx
server {
    listen 8080 ssl;
    server_name <SERVER_HOST>;

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
    server_name <SERVER_HOST>;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;

    location ^~ /ucs.auth.RebacApi/ {
        allow 127.0.0.1;
        allow <SERVER_IP>;
        deny all;
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }

    location / {
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }
}
```

`grpc_ssl_verify off` は nginx から loopback 上の自己署名 gRPC endpoint への upstream
verification のみを無効にする。外部 client の TLS verification は無効化しない。
`x-lore-client-ip` は実機で Service Account 対応時に追加した設定である。bridge 側で
loopback の trusted proxy からの metadata のみを受け付ける構成を確認する。

```bash
sudo ln -s /etc/nginx/sites-available/lore-auth /etc/nginx/sites-enabled/lore-auth
sudo nginx -t
```

既存 nginx site は削除しない。port が競合する場合は既存 configuration を確認して解決する。

## 8. systemd と初期化

`/etc/systemd/system/lore-auth.service`:

```ini
[Unit]
Description=Lore authentication bridge
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/datadrive

[Service]
Type=simple
User=lore
Group=lore
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

`RequiresMountsFor` は mount dependency を設定するが、意図した device が mount されているかの
確認の代わりにはならない。各 `test` の成功を確認してから、新規 DB と signing key を作る。

```bash
sudo -u lore test -r /etc/lore/secrets/entra-client-secret
sudo -u lore test -r /opt/lore/certs/lore-server.key
sudo -u lore test -w /datadrive/lore/auth
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml init-db
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  signing-key generate --kid lore-entra-01

sudo systemctl daemon-reload
sudo systemctl enable --now lore-auth nginx
```

## 9. bridge の受入確認

`<SERVER_HOST>` を置き換える。自己署名 certificate を指定し、TLS verification を有効にして
health と JWKS を確認する。

```bash
systemctl is-enabled lore-auth nginx
systemctl is-active lore-auth nginx
sudo nginx -t
sudo ss -lntup | grep -E ':(8080|8081|18080|18081)\b'
curl --fail --cacert /opt/lore/certs/lore-server.crt \
  https://<SERVER_HOST>:8080/healthz
curl --fail --cacert /opt/lore/certs/lore-server.crt \
  https://<SERVER_HOST>:8080/.well-known/jwks.json
sudo journalctl -u lore-auth -n 100 --no-pager
```

両 service が `enabled` / `active`、health が `ok`、JWKS が応答し、public と loopback の
listener が想定どおりであることを確認する。HTTP health の成功だけでは gRPC の動作や
client の trust は確認できない。続けて [Lore Server](server-setup.md) を構築する。

## 10. 利用者登録と repository へのアクセス

Entra の対象者について email、display name、tenant ID、object ID を管理者が確認する。
`user list` で既存 user を確認し、まだ存在しない場合は作成する。email は例を置き換える。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml user list
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user add --email "<USER_EMAIL>" --name "<DISPLAY_NAME>"
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user bind-identity --idp entra --email "<USER_EMAIL>" \
  --subject "<TENANT_ID>:<OBJECT_ID>"
```

subject が別 user に bind 済みなら上書きせず、Entra 側と既存 binding を確認する。
[Lore Server](server-setup.md) の構築後に対象 repository が作成・登録済みであることを確認し、必要な最小 role を付与する。
以下は `writer` の例である。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  grant add "user:<USER_EMAIL>" "<REPOSITORY>" writer
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  check "<USER_EMAIL>" "<REPOSITORY>" write
```

`check` が `allow` となることを確認し、利用者の Windows client から実際に login と clone
を行う。repository の作成手順と CLI の互換性は使用する revision に合わせて確認する。
CI の login や writer 操作は別途実行して確認する。

## 導入後

DB、JWT signing key、設定を Lore store と同時点の recovery set に含め、復元試験を行う。
Entra client secret と certificate の期限を管理し、certificate は client と runner に先に
配布してから切り替える。実機での更新・証明書運用は
[作業記録](../work/) を参照する。
