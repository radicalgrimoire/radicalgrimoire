# Lore のバックアップと復旧

[実機の更新記録](../work/server-193-update.md) と旧運用資料を
基にした、同一 host 構成の offline backup 手順。一般化した手順と復元試験は未実施である。
実施前に利用者、停止時間、backup 保管先、復元先、承認者を決める。

> [!WARNING]
> backup には repository data、個人情報、client secret、TLS private key、JWT signing key が
> 含まれる。暗号化、アクセス制限、別媒体への保管と保持期限を設定する。復元は既存データを
> 失う可能性があるため、対象と影響を確認し、承認なしに上書きしない。

## 1. recovery set の範囲

以下は [構築例](../setup/002-server-setup.md) の path。実際の設定から path と service 名を確認する。

| 対象 | 構築例 |
| --- | --- |
| Lore store | `/datadrive/lore/store` |
| bridge SQLite database、WAL/SHM、JWT key | `/datadrive/lore/auth` |
| Lore / bridge 設定 | `/opt/lore/config` |
| TLS certificate と private key | `/opt/lore/certs` |
| Entra client secret | `/etc/lore/secrets` |
| 使用 binary | `/opt/lore/bin` |
| systemd unit、nginx site 設定 | `/etc/systemd/system/lore-auth.service`、`loreserver.service`、`/etc/nginx/sites-available/lore-auth` |

上記を**同じ停止期間**の recovery set にする。設定が参照する追加 file、証明書や secret、
filesystem mount、nginx の関連設定も洗い出し、復旧に必要な version と設定を記録する。
SQLite は WAL mode の場合があるため、DB file 単体でなく `-wal` / `-shm` を含む directory を
保存する。

bridge の DB には公開 JWK、鍵 metadata と private key path が保存され、private key 自体は
`jwt.signing_key_dir` にある。鍵 ID と `jwt.active_kid` の整合性を保ち、鍵 directory と
DB を同じ recovery set に含める。bridge は authn / authz token を RS256 で署名し、
Lore Server は JWKS から公開鍵を取得する。
旧 bridge 文書の対象 revision は authz token の TTL を 15 分と説明しているが、対象 revision
と発行方法で確認する。鍵生成 command も revision により異なるため、既存鍵を再生成する前に
`--help` と影響を確認する。

live backup で稼働中の main DB file を単純コピーしてはならない。SQLite の `.backup` または
`VACUUM INTO` を使い、鍵 directory や Lore store との整合性を別途確保する。下記は offline
backup であり、live backup は対象環境で一貫性と復元を検証するまでは実証済み手順としない。

## 2. 停止と backup

1. 利用者と CI に停止を通知し、network からの新規アクセスを止める。
2. 手動 `lore-authctl`、定期 job、その他 DB / store に書き込む process をすべて停止する。
3. Lore Server と bridge を停止し、**両方が inactive になったこと、他の writer が残っていない
   ことを確認してから**コピーする。停止に失敗したら backup を開始しない。

```bash
sudo systemctl stop loreserver
sudo systemctl stop lore-auth
systemctl is-active loreserver lore-auth
```

`is-active` は停止中に非ゼロを返す。出力が両方 `inactive` であることを個別に確認する。
nginx は他の用途を共有する場合があるため、無条件に停止しない。

例では、作成済みの安全な backup volume `/backup/lore` に新しい directory を作る。
`/backup/lore` が意図した filesystem で、source の中ではないこと、空き容量と権限が十分なことを
確認する。変数は同じ shell session 内で使用する。

```bash
BACKUP_DIR="/backup/lore/$(date -u +%Y%m%dT%H%M%SZ)-offline"
sudo mkdir -m 0700 "$BACKUP_DIR"
sudo rsync -aHAX --numeric-ids /datadrive/lore/store/ "$BACKUP_DIR/store/"
sudo rsync -aHAX --numeric-ids /datadrive/lore/auth/ "$BACKUP_DIR/auth/"
sudo rsync -aHAX --numeric-ids /opt/lore/config/ "$BACKUP_DIR/config/"
sudo rsync -aHAX --numeric-ids /opt/lore/certs/ "$BACKUP_DIR/certs/"
sudo rsync -aHAX --numeric-ids /etc/lore/secrets/ "$BACKUP_DIR/secrets/"
sudo rsync -aHAX --numeric-ids /opt/lore/bin/ "$BACKUP_DIR/bin/"
sudo install -d -m 0700 "$BACKUP_DIR/systemd" "$BACKUP_DIR/nginx"
sudo cp -p /etc/systemd/system/lore-auth.service \
  /etc/systemd/system/loreserver.service "$BACKUP_DIR/systemd/"
sudo cp -p /etc/nginx/sites-available/lore-auth "$BACKUP_DIR/nginx/lore-auth"
sudo sha256sum "$BACKUP_DIR/bin/lore" "$BACKUP_DIR/bin/loreserver" \
  "$BACKUP_DIR/bin/lore-auth-server" "$BACKUP_DIR/bin/lore-authctl"
```

各 command の成功を確認する。コピー失敗や容量不足があれば不完全な set として扱い、
原因を解決してから新しい set を作り直す。成功後に set の日時、保存先、対象 revision、
checksum を安全な運用記録に残す。別障害域への暗号化コピーを行う。

停止した service を再開する場合は bridge を先に起動し、health / JWKS を確認してから
Lore Server を起動する。

```bash
sudo systemctl start lore-auth
sudo systemctl is-active lore-auth
curl --fail --cacert /opt/lore/certs/lore-server.crt https://<SERVER_HOST>:8080/healthz
curl --fail --cacert /opt/lore/certs/lore-server.crt https://<SERVER_HOST>:8080/.well-known/jwks.json
sudo systemctl start loreserver
sudo systemctl is-active loreserver
```

上記は自己署名 certificate を trust anchor とする構築例。各確認に失敗した場合は次へ進まず調査する。
利用者の login / clone を確認してからアクセスを再開する。

## 3. 復元と復元試験

**未検証:** 次は安全な復元作業の流れであり、環境別の実際の restore は事前に隔離環境で試験する。

1. 復元する同一時点の recovery set、binary / DB / store の互換性、checksum を確認する。
2. 復元先は production に接続しない隔離環境を準備し、対象 directory と mount を明示する。
   誤った接続先への通知、認証、外部アクセスが発生しないようにする。
3. service とすべての writer を停止する。既存データを保持し、承認済みの空の復元先へ
   `rsync -aHAX --numeric-ids` 等で set の各 directory を対応する path に戻す。
   DB と `-wal` / `-shm`、JWT key、config、certificate、secret、対応 binary を混在させない。
4. 所有権、permission、mount、systemd、nginx config と secret 参照先を確認する。接続先や
   issuer を変更する必要がある場合は、TLS / JWT を含む影響を評価してから設定する。
5. bridge を先に起動し、health / JWKS、次に Lore Server、認証、repository list、clone を確認する。
   必要な write 試験は隔離された repository でのみ行う。
6. 試験結果、復旧所要時間、未確認事項を記録する。本番への復元は別途承認を得る。

新しい server が store に書き込んだ後は、binary だけを旧版に戻さない。rollback の場合も
データを失う範囲と DB migration の互換性を確認し、同じ recovery set を用いる。
