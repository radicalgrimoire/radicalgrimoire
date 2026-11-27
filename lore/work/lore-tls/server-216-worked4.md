# 4. Lore の認証設定と社内向け待受（TLS 版）

新規構築向けの未検証手順。worked1〜3 の設定と社内 CA の信頼が前提。
`lores://` の制約は同じフォルダの README.md を参照する。

## Lore Server の設定

```bash
vim /datadrive/lore/config/gspcd581.toml
```

次を追記する。`auth_url` はクライアントに通知する認証先。

```toml
[environment.endpoint]
auth_url = "https://172.20.11.216:8081"

[server.auth]
jwt_issuer = "https://172.20.11.216:8080"
jwt_audience = ["lore-service", "172.20.11.216"]

[server.auth.jwk]
endpoint = "http://127.0.0.1:18080/.well-known/jwks.json"
```

worked1 で設定した既存の値を変更する。テーブルを重複して追記しない。
`0.0.0.0` は社内だけに制限する設定ではない。公開範囲はネットワークと
ファイアウォールで制御する。

```toml
[server.quic]
host = "0.0.0.0"

[server.grpc]
host = "0.0.0.0"

[server.http]
host = "127.0.0.1"
```

worked1 の `[server.grpc.certificate]` を維持する。bridge の
`repository_create_url` は `https://127.0.0.1:41337` を使う。

## サービスの信頼と起動設定

Lore Server が社内 CA を信頼できるようにする。OS bundle には公開 CA も残す。
自己署名証明書を指定する既存の `SSL_CERT_FILE` があれば置き換え、
複数の drop-in に同じ変数を設定しない。

```bash
sudo env SYSTEMD_EDITOR=vim systemctl edit loreserver
```

```ini
[Unit]
Wants=lore-auth.service nginx.service
After=lore-auth.service nginx.service

[Service]
Environment=SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```

Nginx の systemd サービスには `/datadrive` のマウント依存を設定する。

```bash
sudo env SYSTEMD_EDITOR=vim systemctl edit nginx
```

```ini
[Unit]
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart lore-auth nginx loreserver
sudo systemctl enable lore-auth loreserver
systemctl status lore-auth nginx loreserver --no-pager -l

openssl s_client \
  -connect 127.0.0.1:41337 \
  -CAfile /datadrive/lore/certs/lore-ca.crt \
  -verify_ip 127.0.0.1 \
  -verify_return_error \
  -alpn h2 \
  -brief </dev/null
```

## アカウント

Entra 管理画面で対象ユーザーのテナント ID とオブジェクト ID を確認する。
既存アカウントには `user add` を実行せず、状態を確認してから紐付ける。

```bash
/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  user add --email "<EMAIL>" --name "<DISPLAY_NAME>"

/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  user bind-identity --idp entra --email "<EMAIL>" \
  --subject "<TENANT_ID>:<OBJECT_ID>"
```

社内クライアントには適切な CA を信頼させ、接続先には
`lores://172.20.11.216:41337` を使う。クロニクラーは現状 `lores://` に未対応。
bridge の `default_remote_url` を省略した場合の明示 URL でのログインも未検証。
