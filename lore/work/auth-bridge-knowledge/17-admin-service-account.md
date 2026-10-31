# 管理 UI の service account 作成

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)、[CI Service Account](../../operations/ci-service-account.md)（補足）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

対象 revision の Server settings では Client ID、表示名、既存 group を指定して service account を作成できる。account、group 所属、監査は一括確定し、生成された Client Secret は作成結果に一度だけ表示される。安全な credential store に保存し、紛失時は対象 revision の `service-account rotate` で再発行する。

作成フォームは repository grant と network CIDR を設定しない。別途最小 grant と、実際の接続元に一致する group の CIDR を設定し、runner から login と必要な操作を確認する。
