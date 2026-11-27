# lore-auth-bridgeをcloneする

git clone --branch main --single-branch \
  https://github.com/radicalgrimoire/lore-auth-bridge.git \
  "$HOME/src/lore-auth-bridge"

# ビルドする
cargo build --release --locked \
  -p lore-auth-server \
  -p lore-authctl

ls -lh target/release/lore-auth-server target/release/lore-authctl
sha256sum target/release/lore-auth-server target/release/lore-authctl

# インストールする
sudo install -o root -g root -m 0755 \
  target/release/lore-auth-server \
  target/release/lore-authctl \
  /datadrive/lore/bin/

# フォルダを作っておく
  sudo install -d -o mgs -g mgs -m 0700 \
  /datadrive/lore/auth \
  /datadrive/lore/auth/data \
  /datadrive/lore/auth/keys

# コールバックURL候補はこうなる
https://172.20.11.216:8080/auth/entra/callback

EntraIDの認証に登録する

# lore-auth-bridgeの設定を編集する
# 設定例は同じフォルダの lore-auth-config.md を参照。
# この例の repository_create_url は平文 gRPC 用。TLS を使う場合は接続先と信頼設定を合わせる。

cp -i "$HOME/src/lore-auth-bridge/configs/lore-auth.example.yaml" \
  /datadrive/lore/config/lore-auth.yaml

chmod 0600 /datadrive/lore/config/lore-auth.yaml
vim /datadrive/lore/config/lore-auth.yaml

# 動作用のシークレットファイルを作る
install -m 0600 /dev/null /datadrive/lore/auth/entra-client-secret

vim -n -i NONE -c 'set nobackup nowritebackup noswapfile' \
  /datadrive/lore/auth/entra-client-secret

EntraIDアプリからシークレットを作成。値を保存する

# databaseを作成する

/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  init-db

# 鍵を作る
/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml \
  key generate --kid lore-216-01

# 確認する
bash scripts/verify-entra-client-secret.sh \
  --tenant-id "<TENANT_ID>" \
  --client-id "<CLIENT_ID>" \
  --secret-file "/datadrive/lore/auth/entra-client-secret"

# サービス確認
systemctl list-unit-files 'lore-auth.service' --no-pager
ls -l /etc/systemd/system/lore-auth.service

# サービスの作成
# サービス定義の例は同じフォルダの lore-auth.md を参照。
sudo vim /etc/systemd/system/lore-auth.service

sudo systemctl daemon-reload
sudo systemctl start lore-auth

# サービスの起動確認
systemctl status lore-auth --no-pager -l
ss -lnt '( sport = :18080 or sport = :18081 )'

curl --noproxy '*' -i --max-time 10 \
  http://127.0.0.1:18080/healthz

  curl --noproxy '*' -fsS --max-time 10 \
  http://127.0.0.1:18080/.well-known/jwks.json


# 証明書確認

openssl s_client \
  -connect 127.0.0.1:18081 \
  -CAfile /datadrive/lore/certs/lore-server.crt \
  -verify_ip 127.0.0.1 \
  -verify_return_error \
  -brief </dev/null