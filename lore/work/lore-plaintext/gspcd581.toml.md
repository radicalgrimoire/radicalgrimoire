# 216 の Lore Server 設定

2026-11-09 に確認した `/datadrive/lore/config/gspcd581.toml` の実機設定。

```toml
[server.quic.certificate]
cert_file = "/datadrive/lore/certs/lore-server.crt"
pkey_file = "/datadrive/lore/certs/lore-server.key"

[immutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[mutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[server.quic]
host = "0.0.0.0"

[server.grpc]
host = "0.0.0.0"

[server.http]
host = "127.0.0.1"

[environment.endpoint]
auth_url = "https://172.20.11.216:8081"

[server.auth]
jwt_issuer = "https://172.20.11.216:8080"
jwt_audience = ["lore-service", "172.20.11.216"]

[server.auth.jwk]
endpoint = "http://127.0.0.1:18080/.well-known/jwks.json"

```

## 社内クライアント向けの変更

- QUIC と gRPC の待受を `127.0.0.1` から `0.0.0.0` に変更した。
  TCP・UDP 41337 は全 IPv4 インターフェースで待ち受ける。
- クライアントに通知する `auth_url` を `https://127.0.0.1:8081` から
  `https://172.20.11.216:8081` に変更した。
- HTTP の待受は `127.0.0.1` のまま。
- クロニクラーの `lore://` に合わせるため `[server.grpc.certificate]` を削除し、
  gRPC を平文に変更した。QUIC の証明書設定は残している。

確認時、UFW は無効だった。`0.0.0.0` は社内 CIDR のみに限定する設定ではない。
`lore://` の gRPC では、認証トークンを含む通信は暗号化されない。