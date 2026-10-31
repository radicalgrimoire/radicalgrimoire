# 管理者・IdP 障害からの復旧

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)、[バックアップと復旧](../../operations/backup-recovery.md)（補足）  
**根拠:** [Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#recovery)

## 統合文案

管理者 user を誤って無効化した場合、対象 DB と user を確認してから `lore-authctl user enable` で復旧する。IdP 障害時も host 上の管理 CLI を使った管理変更は可能であり、元文書では CLI の書き込みも監査付き adapter を通る。必要な場合の手動 authn token 発行は通常 login と区別し、credential の安全な受け渡しと有効期限を管理する。

この手順は完全な disaster recovery や IdP 不要での全 user 復旧を保証しない。対象 revision と承認済み運用で事前に検証する。
