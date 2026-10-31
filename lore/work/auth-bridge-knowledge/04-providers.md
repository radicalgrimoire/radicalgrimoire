# IdP と provider ID

**統合先案:** `lore/setup/identity-providers.md`（新規候補）  
**根拠:** [Identity Providers](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/identity-providers.md)、[Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#identity_providers)

## 統合文案

`identity_providers.providers` の key は adapter 種別ではなく、保存される provider instance ID である。複数 issuer や tenant を区別できる安定した名前を使い、`default` は存在する key を参照する。callback は設定した provider ID を含む `/auth/{provider}/callback` と IdP 側の登録を一致させる。

Google は `profile: google` / `oidc_sub` を使い、Workspace の `hd` と個人 account の policy を設定できる。Keycloak は `profile: keycloak` / `oidc_sub` を使い、Google 固有の `personal_accounts` は設定しない。Entra は `profile: entra` / `entra_oid_tid` と必須の `required_tid` を使う。具体的な schema と対象 revision の対応を適用前に確認する。
