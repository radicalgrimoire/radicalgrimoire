# SQLite と鍵のバックアップ

**統合先案:** [バックアップと復旧](../../operations/backup-recovery.md)（補足）  
**根拠:** [Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#backups)

## 統合文案

SQLite は WAL mode を使うため、稼働中の main DB file の単純コピーを live backup としない。offline backup は server と authctl を含むすべての writer を停止し、必要な WAL / SHM と DB を保存する。live backup を行う場合は SQLite の `.backup` または `VACUUM INTO` を使い、署名鍵 directory との整合性を別途確保する。

DB は秘密鍵そのものではなく公開 JWK と秘密鍵 path を保存するため、鍵 directory と同じ時点の recovery set にする。Entra secret、TLS key、Lore store、設定の保護と復元試験も必要である。対象環境の一貫性を確認するまでは live backup を実証済みの recovery 手順としない。
