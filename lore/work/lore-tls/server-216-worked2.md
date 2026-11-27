# 2. lore-auth-bridge の構築（TLS 版）

新規構築向けの未検証手順。worked1 の証明書と CA の準備を先に完了する。
設定例は同じフォルダの `lore-auth.yaml` を参照し、Entra の値を置き換える。

## ビルドとインストール

```bash
git clone --branch main --single-branch \
  https://github.com/radicalgrimoire/lore-auth-bridge.git \
  "$HOME/src/lore-auth-bridge"
cd "$HOME/src/lore-auth-bridge"
git rev-parse HEAD

cargo build --release --locked -p lore-auth-server -p lore-authctl
ls -lh target/release/lore-auth-server target/release/lore-authctl
sha256sum target/release/lore-auth-server target/release/lore-authctl

sudo install -o root -g root -m 0755 \
  target/release/lore-auth-server target/release/lore-authctl \
  /datadrive/lore/bin/
sudo install -d -o mgs -g mgs -m 0700 \
  /datadrive/lore/auth /datadrive/lore/auth/data /datadrive/lore/auth/keys
```

Entra アプリには `https://172.20.11.216:8080/auth/entra/callback` を登録する。
ブランチの取得時点により bridge のバージョンは変わる。

## bridge の設定と初期化

```bash
cp -i "$HOME/src/lore-auth-bridge/configs/lore-auth.example.yaml" \
  /datadrive/lore/config/lore-auth.yaml
chmod 0600 /datadrive/lore/config/lore-auth.yaml
vim /datadrive/lore/config/lore-auth.yaml
```

TLS 版の例に合わせ、`lore.repository_create_url` は
`https://127.0.0.1:41337` とする。`default_remote_url` は省略する。
構築済み bridge のバージョンは `lores://` をこの設定に受け付けず、
省略時に明示 URL でログインできるかは未検証。

新規環境で、Entra の client secret を次のファイルに保存する。既存ファイルを
空にしたり、既存の DB・署名鍵を再初期化したりしない。ファイル作成に失敗したら
初期化に進まず、原因を確認する。

```bash
(umask 077; set -o noclobber; : > /datadrive/lore/auth/entra-client-secret) &&
  vim -n -i NONE -c 'set nobackup nowritebackup noswapfile' \
  /datadrive/lore/auth/entra-client-secret

/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml init-db
/datadrive/lore/bin/lore-authctl \
  --config /datadrive/lore/config/lore-auth.yaml key generate --kid lore-216-01

bash scripts/verify-entra-client-secret.sh \
  --tenant-id "<TENANT_ID>" \
  --client-id "<CLIENT_ID>" \
  --secret-file "/datadrive/lore/auth/entra-client-secret"
```

## サービスと信頼設定

サービス定義は平文版の `lore-auth.md` の unit を参考にする。TLS 版では、その
自己署名証明書向け drop-in ではなく、同じフォルダの `lore-auth-trust.conf` を使う。
OS bundle には社内 CA と、Entra 接続に必要な公開 CA の両方を含める。

```bash
sudo vim /etc/systemd/system/lore-auth.service
sudo env SYSTEMD_EDITOR=vim systemctl edit lore-auth
```

drop-in に以下を設定する。同じ `SSL_CERT_FILE` を別の drop-in で指定しない。

```ini
[Service]
Environment=SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```

```bash
sudo systemctl daemon-reload
sudo systemctl start lore-auth
systemctl status lore-auth --no-pager -l
ss -lnt '( sport = :18080 or sport = :18081 )'
curl --noproxy '*' -i --max-time 10 http://127.0.0.1:18080/healthz
curl --noproxy '*' -fsS --max-time 10 http://127.0.0.1:18080/.well-known/jwks.json

openssl s_client \
  -connect 127.0.0.1:18081 \
  -CAfile /datadrive/lore/certs/lore-ca.crt \
  -verify_ip 127.0.0.1 \
  -verify_return_error \
  -brief </dev/null
```
