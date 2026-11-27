# OS・CPU・実行ユーザーを確認
cat /etc/os-release
uname -m
id

df -h /
command -v git cargo rustc lore loreserver

# 既存サービスの有無を確認
systemctl list-unit-files 'loreserver.service' --no-pager

# とりあえず
apt-get update -y 
apt upgrade

# ビルドするするためのモジュールをインストールする
sudo apt-get install -y build-essential ca-certificates cmake curl git libssl-dev openssl pkg-config

# 汎用ユーザー（非root）で実行
# Rustのインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

mgs@gspcd581:~$ source "$HOME/.cargo/env"
mgs@gspcd581:~$ rustc --version
rustc 1.99.1 (58cf8f9c3 2026-10-13)
mgs@gspcd581:~$ cargo --version
cargo 1.99.1 (5f94df478 2026-08-27)

# loreサーバーをcloneする
mkdir -p "$HOME/src"
git clone --branch develop --single-branch \
  https://github.com/radicalgrimoire/lore.git \
  "$HOME/src/lore"

# developであることを確認する
cd "$HOME/src/lore"
mgs@gspcd581:~/src/lore$ git branch --show-current
develop
mgs@gspcd581:~/src/lore$ git rev-parse HEAD
73a455d6a957004fdef2a9b3953cc9002263ca28

# lore-cliとlore-serverをビルドする
cargo build --release --locked \
  -p lore-client --bin lore \
  -p lore-server --bin loreserver

# target/release/ にビルドされた物があるか確認
ls -lh target/release/lore target/release/loreserver
target/release/lore --version
target/release/loreserver --version
sha256sum target/release/lore target/release/loreserver

target/release/lore --version
target/release/loreserver --version
sha256sum target/release/lore target/release/loreserver
-rwxrwxr-x 2 mgs mgs 283M Nov  9 06:30 target/release/lore
-rwxrwxr-x 2 mgs mgs 338M Nov  9 06:31 target/release/loreserver
lore 0.13.1-nightly+local
loreserver 0.13.1-nightly
9813b8cb3a8f6372ad57a43eded8ffd877346c9b720f372c6fb7618fd013e3a5  target/release/lore
e2b158be12131f033e82c3cacea68f3e7cadf9852bd207176bce8603ddc784c4  target/release/loreserver

# ディスク、パス確認
printf '%s\n' "$PATH" | tr ':' '\n'
ls -ld /usr/local/bin /datadrive
ls -ld /usr/local/bin/lore /datadrive/lore

# LORE-CLIインストールコマンドを実行する
sudo install -o root -g root -m 0755 \
  target/release/lore /usr/local/bin/lore

# バージョン確認
lore --version
sha256sum target/release/lore /usr/local/bin/lore

# LOREサーバーの追加
sudo install -d -o root -g root -m 0755 \
  /datadrive/lore /datadrive/lore/bin

sudo install -o root -g root -m 0755 \
  target/release/loreserver /datadrive/lore/bin/loreserver

/datadrive/lore/bin/loreserver --version
sha256sum target/release/loreserver /datadrive/lore/bin/loreserver

# LOREサーバー用のディレクトリ準備
sudo install -d -o mgs -g mgs -m 0750 \
  /datadrive/lore/config \
  /datadrive/lore/certs \
  /datadrive/lore/store

  mgs@gspcd581:~/src/lore$ ls -ld /datadrive/lore/{bin,config,certs,store}
drwxr-xr-x 2 root root 4096 Nov  9 06:43 /datadrive/lore/bin
drwxr-x--- 2 mgs  mgs  4096 Nov  9 06:45 /datadrive/lore/certs
drwxr-x--- 2 mgs  mgs  4096 Nov  9 06:45 /datadrive/lore/config
drwxr-x--- 2 mgs  mgs  4096 Nov  9 06:45 /datadrive/lore/store
mgs@gspcd581:~/src/lore$

# 自己証明書を作る
(
  umask 077
  openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
    -subj "/CN=172.20.11.216" \
    -addext "basicConstraints=critical,CA:FALSE" \
    -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
    -addext "extendedKeyUsage=serverAuth" \
    -addext "subjectAltName=IP:172.20.11.216,DNS:localhost,IP:127.0.0.1" \
    -keyout /datadrive/lore/certs/lore-server.key \
    -out /datadrive/lore/certs/lore-server.crt
)

openssl x509 -in /datadrive/lore/certs/lore-server.crt \
  -noout -subject -issuer -dates -ext subjectAltName

ls -l /datadrive/lore/certs

# コンフィグを作成する
cat > /datadrive/lore/config/gspcd581.toml <<'EOF'
[server.quic.certificate]
cert_file = "/datadrive/lore/certs/lore-server.crt"
pkey_file = "/datadrive/lore/certs/lore-server.key"

[immutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10

[mutable_store.local]
path = "/datadrive/lore/store"
flush_delay_seconds = 10
EOF

## テスト中だけ、このサーバー自身からでしか繋げられないようにする
cat >> /datadrive/lore/config/gspcd581.toml <<'EOF'

[server.quic]
host = "127.0.0.1"

[server.grpc]
host = "127.0.0.1"

[server.http]
host = "127.0.0.1"
EOF

# サービス設定

ls -l /etc/systemd/system/loreserver.service

```
sudo tee /etc/systemd/system/loreserver.service > /dev/null <<'EOF'
[Unit]
Description=LORE Server
After=network.target
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive

[Service]
Type=simple
User=mgs
Group=mgs
UMask=0077
ExecStart=/datadrive/lore/bin/loreserver --config /datadrive/lore/config --env gspcd581
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

```
sudo systemctl daemon-reload
sudo systemctl start loreserver
```

```
systemctl status loreserver --no-pager -l
ss -lntu '( sport = :41337 or sport = :41339 )'
```

# ヘルスチェック
curl --noproxy '*' -i --max-time 10 \
  http://127.0.0.1:41339/health_check

