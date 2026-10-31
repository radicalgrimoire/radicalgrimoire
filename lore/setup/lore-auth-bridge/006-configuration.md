# bridge 設定

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/opt/lore/config/lore-auth.yaml` を作成し、すべての `<...>` を置き換える。
以下は実機で使った revision の設定例である。
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
`<tenant-id>:<object-id>` を user に bind する。[利用者登録](010-user-onboarding.md)
を参照する。

次は [nginx 設定](007-nginx.md)。
