# 確認済みメールによる招待

**統合先案:** [authctl 操作](../../operations/authctl.md)（補足）  
**根拠:** [Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#identity_providers)、[Authctl](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/authctl.md#user-invite)

## 統合文案

確認済み email を返す IdP では、管理者が `user invite --idp <provider-id> --email <email> --name <name>` で user と pending invitation を登録できる。`verified_email_invitation` では、同じ provider と issuer の招待に一致する verified email が初回 login で確認された場合に binding が作成される。`disabled` では invitation は作成されても login で消費されない。

`allowed_email_domains` は invitation 消費時の追加条件であり、すべての login に適用される allowlist ではない。既存 binding は provider、issuer、subject で解決される。未検証 email を本人確認に使わず、Entra では管理者確認済みの subject を明示的に bind する方法を選べる。
