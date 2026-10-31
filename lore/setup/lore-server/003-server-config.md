# Lore Server 設定

先に [前提条件](README.md)、[build・配置](001-build.md)、
[directory の作成](002-directories.md) を確認する。

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

次は [systemd と起動](004-systemd.md)。
