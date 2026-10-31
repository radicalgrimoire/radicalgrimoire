# Entra 連携の検証根拠

**統合先案:** [Lore の入口](../../README.md)（補足）  
**根拠:** [Entra 連携の検証記録](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id-integration-evidence.md#実機で確認したこと)、[更新履歴](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id-bridge-update-history.md)

## 統合文案

過去の実機記録では、Entra の email claim が未検証の環境で管理者による object ID binding、再実行、監査記録、browser login、repository 作成と writer 操作を確認した。該当記録では `cargo check -p lore-authctl` と `cargo test -p lore-auth-adapters --test sqlite` の成功、SQLite test 24 件を報告している。

これは記録当時の結果であり、現在の revision で同じ件数・coverage・実機動作を確認した意味ではない。記録当時の未実装 test や削除済み onboarding script も現状と混同しない。個別環境のアドレス、利用者名、tenant ID は一般文書へ転記しない。
