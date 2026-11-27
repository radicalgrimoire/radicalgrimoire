# bridge 設定

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/opt/lore/config/lore-auth.yaml` を作成し、すべての `<...>` を置き換える。
以下は 216 の実機設定を、path と値を置き換えて一般化した例である。
対象 revision の bridge は各設定 object の未知の key を parse error として扱う。
使用 binary の schema に合わせ、綴り間違いや未対応の key を残さない。

> [!WARNING]
> この例の `admin_emails` は管理 UI を有効にする。nginx の例には管理画面専用の
> 送信元制限がないため、公開前に [管理 Web UI の設定と操作](../../admin-webtools/README.md) に従って
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

database:
  path: "/datadrive/lore/auth/data/lore-auth.sqlite3"

authz:
  backend: rebac

jwt:
  issuer: "https://<SERVER_HOST>:8080"
  audience: ["lore-service", "<SERVER_HOST>"]
  ttl_seconds: 32400
  signing_key_dir: "/datadrive/lore/auth/keys"
  active_kid: "lore-entra-01"

lore:
  auth_url: "https://<SERVER_HOST>:8081"
  repository_create_url: "http://127.0.0.1:41337"

admin:
  admin_emails: ["<ADMIN_EMAIL>"]

security:
  device_code_ttl_seconds: 600
  device_poll_interval_seconds: 3
  session_ttl_seconds: 3600
  rebac_allowed_peer_cidrs: ["127.0.0.1/32", "::1/128"]
```

上記 `lore` は社内 IP / plaintext の例で、管理画面からの repository 作成先を
平文の loopback gRPC とする。216 実機では `default_remote_url` は省略されている。
DNS / TLS では `repository_create_url` を `https://127.0.0.1:41337` に変更し、
bridge がその接続先の証明書を検証できるようにする。
記録時点の bridge は `default_remote_url` に `lores://` を受け付けない。
省略時の明示 URL でのログインは未検証のため、使用 revision で確認する。
JWT issuer / audience、callback と証明書の名前は DNS 名に揃える。

```bash
sudo chown root:lore /opt/lore/config/lore-auth.yaml
sudo chmod 0640 /opt/lore/config/lore-auth.yaml
```

216 実機では `email_binding: verified_email_invitation` が設定されている。
招待を使わない方針への変更は実機に反映されていない。
利用者は管理者が `<tenant-id>:<object-id>` を確認して直接 bind する。
[管理者ユーザーの作成](010-admin-user-setup.md)を参照する。

次は [nginx 設定](007-nginx.md)。
