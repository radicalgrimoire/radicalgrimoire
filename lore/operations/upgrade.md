# Lore Server / bridge の更新

[Lore Server 更新記録](../work/server-193-update.md) と
[bridge 更新記録](../work/server-215-20261022-01.md) を基にした同一 host 向けの手順。
実環境により service 名、path、DB migration、wire 互換性は異なる。一般化した手順は未検証。

## 1. 更新前の確認

1. 対象の Lore / bridge / Windows CLI revision、release note、wire・token store・SQLite / store
   migration の互換性を確認する。公式版と fork が同じ機能を持つと決めつけない。
2. 更新前後の binary、checksum、rollback 条件、停止時間、影響範囲を確認する。
3. 更新後の受入用 user と repository、CI runner を用意する。write 試験は専用 repository または
   承認済み branch で行う。
4. [バックアップ・復旧](backup-recovery.md) に従い writer を停止して同一時点の recovery set を
   作る。**以下の切替は、backup 完了後も `loreserver` と `lore-auth` が停止している状態で行う。**

更新後に新しい data が書かれた場合、旧 backup への復元ではその後の変更が失われる。
SQLite migration を含む bridge 更新も、単純に旧 binary を戻せると仮定しない。

## 2. 新 binary の準備

信頼済み配布物または source revision から、運用中の binary とは別 directory に準備する。
配布元、revision、checksum、architecture と version を確認する。source build の例:

```bash
cd "$HOME/src/lore"
git status --short
git fetch --prune origin
# clean なことを確認してから <LORE_REVISION> を置き換える
git checkout --detach <LORE_REVISION>
git rev-parse HEAD
source "$HOME/.cargo/env"
cargo build --release -p lore-client --bin lore -p lore-server --bin loreserver

cd "$HOME/src/lore-auth-bridge"
git status --short
git fetch --prune origin
# clean なことを確認してから <BRIDGE_REVISION> を置き換える
git checkout --detach <BRIDGE_REVISION>
git rev-parse HEAD
cargo build --release -p lore-auth-server -p lore-authctl
```

変更しない側の build は省略する。作業 tree が clean でない場合は checkout せず、変更の所有者と
対応を決める。build に失敗した場合、稼働 binary を切り替えない。

## 3. binary の切替

各 source path と権限を確認し、更新する component だけを配置する。例は構築手順の path を使う。
旧 binary は recovery set に保存済みであることを確認する。

```bash
# Lore を更新する場合
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/lore" /opt/lore/bin/lore
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore/target/release/loreserver" /opt/lore/bin/loreserver

# bridge を更新する場合
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-auth-server" /opt/lore/bin/lore-auth-server
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-authctl" /opt/lore/bin/lore-authctl
```

各 install の成功を確認する。一部が失敗した場合は service を起動せず、状態を調査する。
bridge の SQLite migration が後方互換と実証されている場合を除き、binary だけの rollback はしない。

## 4. 起動と受入

bridge を先に起動し、TLS 検証付きで health と JWKS を確認してから Lore Server を起動する。
各確認に失敗したら次へ進まず調査する。

```bash
sudo systemctl start lore-auth
sudo systemctl is-active lore-auth
curl --fail --cacert /opt/lore/certs/lore-server.crt https://<SERVER_HOST>:8080/healthz
curl --fail --cacert /opt/lore/certs/lore-server.crt https://<SERVER_HOST>:8080/.well-known/jwks.json
sudo systemctl start loreserver
sudo systemctl is-active loreserver
/opt/lore/bin/lore --version
/opt/lore/bin/loreserver --version
sudo journalctl -u lore-auth -u loreserver -n 100 --no-pager
```

自己署名 certificate を trust anchor とする構築例である。CA を利用する場合は `--cacert` を
実際の trust anchor に替える。listener、利用者の再 login、repository list、clone、
必要な CI login / clone と承認済み write を確認する。token store が移行されない場合は
client で再 login する。

## 5. rollback

service と writer を停止し、migration の互換性と更新後データの扱いを判断する。
旧版と新 data の互換性が明確に確認できない場合、binary のみ差し戻さず、
[同時点の recovery set](backup-recovery.md#3-復元と復元試験) から承認済み手順で復元する。
復元後は bridge、Lore、client の順に受入確認し、結果と失われた変更を記録する。
