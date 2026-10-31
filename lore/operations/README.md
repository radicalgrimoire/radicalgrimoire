# Lore 運用ガイド

Lore Server と `lore-auth-bridge` の運用、障害対応、検証に関する資料。
一般化した手順は実環境で通し検証していない。実施前に対象環境、binary の revision、
設定と各資料の注意事項を確認する。

## ドキュメント

- [TLS 証明書の確認とトラブルシューティング](001-tls-troubleshooting.md) — 接続、信頼設定、証明書の更新。
- [バックアップと復旧](002-backup-recovery.md) — offline backup、復元と復元試験。
- [CI Service Account の設定](003-ci-service-account.md) — runner の認証、権限と secret rotation。
- [Lore Server / bridge の更新](004-upgrade.md) — 更新前の確認、切替、受入と rollback。
- [token 発行と device flow](005-token-flows.md) — 管理 CLI、Web token、device flow。
- [bridge の開発・互換性検証](006-bridge-validation.md) — build、test、E2E、claim contract。

## 関連資料

- [bridge 管理 Web UI](../admin-webtools/README.md) — 公開範囲の制限と管理操作。
- [利用・管理ガイド](../guides/README.md) — Lore CLI と `lore-authctl` の操作。
