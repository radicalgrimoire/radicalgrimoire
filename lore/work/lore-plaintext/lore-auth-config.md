# 216 の lore-auth.yaml

2026-11-09 に確認した `/datadrive/lore/config/lore-auth.yaml` の実機設定。
コメントを省いた記録であり、秘密情報の値は含まない。
以前の端末出力は [lore-auth.yaml.md](./lore-auth.yaml.md) に残している。

```yaml
server:
  listen: "127.0.0.1:18080"
  grpc_listen: "127.0.0.1:18081"
  grpc_tls_cert_file: "/datadrive/lore/certs/lore-server.crt"
  grpc_tls_key_file: "/datadrive/lore/certs/lore-server.key"
  public_base_url: "https://172.20.11.216:8080"

identity_providers:
  default: entra
  providers:
    entra:
      type: oidc
      profile: entra
      display_name: "Microsoft Entra ID"
      issuer: "https://login.microsoftonline.com/ec5c9760-1e1d-4de3-a9ff-c2fcf61d617f/v2.0"
      client_id: "980c48a2-e30f-4fee-a8c6-21b831de9979"
      client_secret_file: "/datadrive/lore/auth/entra-client-secret"
      redirect_url: "https://172.20.11.216:8080/auth/entra/callback"
      scopes:
        - openid
        - email
        - profile
      pkce: required
      subject:
        strategy: entra_oid_tid
        required_tid: "ec5c9760-1e1d-4de3-a9ff-c2fcf61d617f"
      trust:
        email_binding: verified_email_invitation

database:
  path: "/datadrive/lore/auth/data/lore-auth.sqlite3"

authz:
  backend: rebac

jwt:
  issuer: "https://172.20.11.216:8080"
  audience:
    - "lore-service"
    - "172.20.11.216"
  ttl_seconds: 32400
  signing_key_dir: "/datadrive/lore/auth/keys"
  active_kid: "lore-216-01"

lore:
  auth_url: "https://172.20.11.216:8081"
  repository_create_url: "http://127.0.0.1:41337"

admin:
  admin_emails: ["ueno.s@gamestudio.co.jp", "kobayashi.y@gamestudio.co.jp"]

security:
  device_code_ttl_seconds: 600
  device_poll_interval_seconds: 3
  session_ttl_seconds: 3600
  rebac_allowed_peer_cidrs:
    - "127.0.0.1/32"
    - "::1/128"
```

`default_remote_url` は実機ではコメントアウトされている。
`repository_create_url` は平文のローカル Lore gRPC に接続するための設定。
bridge の信頼バンドルは [lore-auth.md](./lore-auth.md) に記録した。

実機の `email_binding` は現在 `verified_email_invitation` であり、
`disabled` ではない。招待を使わない運用方針への反映は未完了。
