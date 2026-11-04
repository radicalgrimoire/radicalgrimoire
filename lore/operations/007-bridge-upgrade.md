# lore-auth-bridge の更新

[bridge 更新記録](../work/server-215-20261022-01.md) を基にした、Lore Server と同一 host に
配置した bridge の更新手順。Lore Server を更新する場合は [Lore Server の更新](004-upgrade.md)
を参照する。実環境により service 名、path、DB migration、wire 互換性は異なる。
一般化した手順は未検証。

## 1. 更新前の確認

1. 対象の bridge / Lore / Windows CLI revision、release note、wire・token store・SQLite
   migration の互換性を確認する。公式版と fork が同じ機能を持つと決めつけない。
2. 更新前後の binary、checksum、rollback 条件、停止時間、影響範囲を確認する。
3. 更新後の受入用 user と repository、CI runner を用意する。write 試験は専用 repository または
   承認済み branch で行う。
4. [バックアップ・復旧](002-backup-recovery.md) に従い writer を停止して同一時点の recovery set を
   作る。**以下の切替は、backup 完了後も `loreserver` と `lore-auth` が停止している状態で行う。**

更新後に新しい data が書かれた場合、旧 backup への復元ではその後の変更が失われる。
SQLite migration を含む更新では、単純に旧 binary を戻せると仮定しない。

特に bridge `b332e35` の `phase7_remove_existing_group_nests_20261030` migration は、
server または authctl が DB を開く際に既存の group 間所属を一度解除して監査する。
対象 revision では UI / CLI から nested group を新規作成できない。更新前に DB を backup し、
継承していた repository grant と Service Account の許可 CIDR を洗い出し、必要な直接所属・
権限を計画する。残存する関係は管理 UI または `group nest remove` で解除できる。
発行済み token は取り消されない。実際の migration は対象 revision で確認する。

## 2. 新 binary の準備

信頼済み配布物または source revision から、運用中の binary とは別 directory に準備する。
配布元、revision、checksum、architecture と version を確認する。source build の例:

```bash
cd "$HOME/src/lore-auth-bridge"
git status --short
git fetch --prune origin
# clean なことを確認してから <BRIDGE_REVISION> を置き換える
git checkout --detach <BRIDGE_REVISION>
git rev-parse HEAD
source "$HOME/.cargo/env"
cargo build --release -p lore-auth-server -p lore-authctl
```

作業 tree が clean でない場合は checkout せず、変更の所有者と対応を決める。
build に失敗した場合、稼働 binary を切り替えない。

## 3. binary の切替

各 source path と権限を確認し、bridge の binary を配置する。例は構築手順の path を使う。
旧 binary は recovery set に保存済みであることを確認する。

```bash
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-auth-server" /opt/lore/bin/lore-auth-server
sudo install -o root -g root -m 0755 \
  "$HOME/src/lore-auth-bridge/target/release/lore-authctl" /opt/lore/bin/lore-authctl
```

各 install の成功を確認する。一部が失敗した場合は service を起動せず、状態を調査する。
SQLite migration が後方互換と実証されている場合を除き、binary だけの rollback はしない。

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
sudo journalctl -u lore-auth -u loreserver -n 100 --no-pager
```

自己署名 certificate を trust anchor とする構築例である。CA を利用する場合は `--cacert` を
実際の trust anchor に替える。listener、利用者の再 login、repository list、clone、
必要な CI login / clone と承認済み write を確認する。token store が移行されない場合は
client で再 login する。

## 5. rollback

service と writer を停止し、migration の互換性と更新後データの扱いを判断する。
旧版と新 data の互換性が明確に確認できない場合、binary のみ差し戻さず、
[同時点の recovery set](002-backup-recovery.md#3-復元と復元試験) から承認済み手順で復元する。
復元後は bridge、Lore、client の順に受入確認し、結果と失われた変更を記録する。
