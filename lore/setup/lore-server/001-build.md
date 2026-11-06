# Lore の build と配置

先に [構築手順の前提条件](README.md) を確認する。一般化した手順は別環境で
通し検証していない。

実機では fork を利用した。TLS gRPC 対応を含み bridge と互換性のある revision を選ぶ。

```bash
source "$HOME/.cargo/env"
git clone https://github.com/radicalgrimoire/lore.git "$HOME/src/lore"
cd "$HOME/src/lore"
git checkout --detach <LORE_REVISION>
git rev-parse HEAD
cargo build --release -p lore-client --bin lore -p lore-server --bin loreserver

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

## 補足: `install` コマンド

`install` は GNU coreutils の標準コマンドで、package の導入ではなく配置用のコピーを行う。
`cp` と `chmod`、`chown` を 1 回で実行でき、配置先を上書きせず新しい file に置き換えるため、
実行中の binary でも `Text file busy` になりにくい。

## 補足: 更新手順

更新時も同じ流れで、source を更新して build し、`install` で binary を置き換える。

```bash
cd "$HOME/src/lore"
/opt/lore/bin/loreserver --version   # 更新前の version を記録する
git fetch --tags
git checkout --detach <NEW_LORE_REVISION>
git rev-parse HEAD
cargo build --release -p lore-client --bin lore -p lore-server --bin loreserver

sudo cp -p /opt/lore/bin/lore /opt/lore/bin/lore.bak
sudo cp -p /opt/lore/bin/loreserver /opt/lore/bin/loreserver.bak
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/lore" /opt/lore/bin/lore
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/loreserver" /opt/lore/bin/loreserver
sudo systemctl restart loreserver
systemctl is-active loreserver
```

- `install` で置き換えても、起動中の process は古い binary のまま動く。`systemctl restart`
  するまで更新は反映されない。
- 更新前に release note や commit log を確認し、設定 file や DB 形式の変更がないか確かめる。
- 不具合時は `.bak` を戻して restart する。更新前後の commit hash を運用記録に残す。
- client と server の互換性を確認し、必要なら Windows client も同じ revision に揃える。

次は [directory の作成](002-directories.md)。
