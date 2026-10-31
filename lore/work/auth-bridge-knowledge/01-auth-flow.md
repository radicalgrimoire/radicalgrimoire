# 認証・認可の経路

**統合先案:** [Lore の入口](../../README.md)（補足）  
**根拠:** [bridge README](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/README.md#これは何か--どう接続するか)

## 統合文案

bridge は IdP で確認した identity を登録済み user に対応付け、ログインの証明となる authn token を発行する。Lore CLI は repository 操作時に `UrcAuthApi` で権限を評価し、短命の repository scoped authz token を取得する。Lore Server は JWKS で署名を検証し、`RebacApi` を通じて repository の作成・削除を bridge に同期する。認証の成功だけでは repository の権限は付与されない。

**確認:** 実際の接続先、token の有効期間と Lore 側の対応 revision を確認する。
