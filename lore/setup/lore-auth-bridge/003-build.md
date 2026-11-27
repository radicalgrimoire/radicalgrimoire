# bridge の build・配置

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

実機では `radicalgrimoire` の fork を利用している。Entra identity binding、callback 対応を
含み、Lore Server と互換性のある revision を選ぶ。最新 `main` が同じ動作をするとは限らない。

```bash
source "$HOME/.cargo/env"
git clone https://github.com/radicalgrimoire/lore-auth-bridge.git \
  "$HOME/src/lore-auth-bridge"
cd "$HOME/src/lore-auth-bridge"
git checkout --detach <BRIDGE_REVISION>
git rev-parse HEAD
cargo build --release --locked -p lore-auth-server -p lore-authctl
```

Entra callback を GET query として受ける revision では、authorization request に
`response_mode=query` が必要である。選択した revision に含まれることを確認し、欠ける場合は
互換性を確認した修正版を使う。build した commit hash と変更の有無を運用記録に残す。

```bash
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-auth-server" \
  /opt/lore/bin/lore-auth-server
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-authctl" /opt/lore/bin/lore-authctl
/opt/lore/bin/lore-authctl --help
```

次は [TLS certificate の作成](004-tls.md)。
