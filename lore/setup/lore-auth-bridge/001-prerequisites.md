# 前提 package と build 環境

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

sudo を使える管理 user で実行する。Rust toolchain と source はその管理 user の home に置き、
service user の home には置かない。

```bash
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential ca-certificates cmake curl git libssl-dev nginx openssl \
  pkg-config rsync

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
rustc --version
cargo --version
```

次は [service user と directory](002-service-user.md)。
