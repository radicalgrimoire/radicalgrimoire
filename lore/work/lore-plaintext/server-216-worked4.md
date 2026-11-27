# 平文版: Lore gRPC は TLS を有効にせず、lore:// で接続する。
# 認証用 Nginx の HTTPS と bridge の gRPC TLS は引き続き使用する。
# TLS 版は ../lore-tls/server-216-tls.md を参照。

vim /datadrive/lore/config/gspcd581.toml

[environment.endpoint]
auth_url = "https://172.20.11.216:8081"

[server.auth]
jwt_issuer = "https://172.20.11.216:8080"
jwt_audience = ["lore-service", "172.20.11.216"]

[server.auth.jwk]
endpoint = "http://127.0.0.1:18080/.well-known/jwks.json"


追記する

# worked1 で設定した待受を編集する。新たに追記せず、既存の値を変更する。
# QUIC と gRPC は全インターフェースで待ち受ける。HTTP は localhost のまま。
# 0.0.0.0 は社内ネットワークだけにアクセスを制限する設定ではない。
[server.quic]
host = "0.0.0.0"

[server.grpc]
host = "0.0.0.0"

[server.http]
host = "127.0.0.1"


sudo vim /etc/systemd/system/loreserver.service

[Service] の中に、次の 1 行を追加してください。
Environment=SSL_CERT_FILE=/datadrive/lore/certs/lore-server.crt

sudo systemctl daemon-reload


Nginx の systemd サービスに追加設定を作るコマンド
  sudo env SYSTEMD_EDITOR=vim systemctl edit nginx

# 平文版では [server.grpc.certificate] を設定しない。
# bridge の repository_create_url は http://127.0.0.1:41337 を使う。
sudo systemctl restart loreserver
systemctl status loreserver --no-pager -l

sudo env SYSTEMD_EDITOR=vim systemctl edit loreserver
[Unit]
Wants=lore-auth.service nginx.service
After=lore-auth.service nginx.service

mgs@gspcd581:~/src/lore-auth-bridge$ sudo systemctl enable lore-auth loreserver
Created symlink '/etc/systemd/system/multi-user.target.wants/lore-auth.service' → '/etc/systemd/system/lore-auth.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/loreserver.service' → '/etc/systemd/system/loreserver.service'.


# アカウントを作成し、Entra ID のユーザーに紐付ける。
# Entra 管理画面で対象ユーザーのテナント ID とオブジェクト ID を確認する。
# 既存アカウントには user add を実行せず、状態を確認してから紐付ける。
/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  user add --email "<EMAIL>" --name "<DISPLAY_NAME>"

/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  user bind-identity --idp entra --email "<EMAIL>" \
  --subject "<TENANT_ID>:<OBJECT_ID>"


  sudo vim /etc/nginx/sites-available/lore-auth

  ```
  server {
    listen 127.0.0.1:8080 ssl;
    listen 172.20.11.216:8080 ssl;
    server_name 172.20.11.216;

    allow 127.0.0.1;
    allow 172.20.16.71;
    deny all;
  ```


  Windows で繋げる

  Test-NetConnection 172.20.11.216 -Port 8080

  