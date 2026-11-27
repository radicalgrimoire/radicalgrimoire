# Lore の build と配置

先に [構築手順の前提条件](README.md) を確認する。一般化した手順は別環境で
通し検証していない。

実機では fork を利用した。bridge と互換性のある revision を選ぶ。
DNS / TLS を選ぶ場合は Lore gRPC の TLS 対応も必要。

```bash
source "$HOME/.cargo/env"
git clone https://github.com/radicalgrimoire/lore.git "$HOME/src/lore"
cd "$HOME/src/lore"
git checkout --detach <LORE_REVISION>
git rev-parse HEAD
cargo build --release --locked -p lore-client --bin lore -p lore-server --bin loreserver

sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/lore" /opt/lore/bin/lore
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/loreserver" /opt/lore/bin/loreserver
/opt/lore/bin/lore --version
/opt/lore/bin/loreserver --version
```

build した commit hash と変更の有無を運用記録に残す。既存環境の動作確認済み binary を使う
場合は配布元、revision、checksum、license、client/server 互換性を確認する。DB、store、
secret や鍵を新環境へコピーしない。

更新時は構築時の command をそのまま再実行せず、対象環境と revision の差異を確認する。
実機の更新記録は [193 の更新手順](../../work/server-193-update2.md)を参照する。

次は [directory の作成](002-directories.md)。
