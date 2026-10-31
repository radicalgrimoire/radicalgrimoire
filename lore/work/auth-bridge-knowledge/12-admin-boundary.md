# 管理 UI の有効化と境界

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)（補足）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#ui-の有効化)、[Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#admin)

## 統合文案

`admin.admin_emails` が空または未設定なら `/admin` は mount されない。有効時は OIDC login 後、有効 user の正規化済み email が管理者一覧と一致する必要がある。対象 revision では未ログインの `/admin` GET は login に redirect されるため、UI の有効化自体は外部から判別できる。非管理者や許可外 peer は 404 を返す。

管理 UI と関連 API は reverse proxy の公開境界で制限する。`admin_allowed_peer_cidrs` は bridge が直接見る TCP peer を検査し、`X-Forwarded-For` を信頼しない。proxy 経由ではこの設定だけで外部 client を区別できない。管理者であることと repository 権限は別であり、`global_repository_admin` を有効にする場合は全 repository への暗黙の権限と発行済み token への影響を評価する。
