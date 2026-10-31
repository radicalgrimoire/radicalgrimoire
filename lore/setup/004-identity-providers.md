# Identity Provider と招待

bridge は IdP が認証した external identity を登録済み user と照合する。以下は
bridge `b332e35` の文書に基づく説明であり、設定 schema、対象 binary と IdP の挙動を
導入前に確認する。この一般化された手順は実環境で通し検証していない。

## provider の識別

`identity_providers.providers` の key は保存される provider instance ID であり、
`oidc` のような adapter 種別ではない。複数 issuer や tenant を区別できる安定した名前を使い、
`default` は存在する key を参照する。OIDC の callback `/auth/{provider}/callback` を
設定と IdP 側で完全一致させる。

- Google: `profile: google`、`subject.strategy: oidc_sub`。Workspace の `hd` claim と
  personal account policy を設定できる。
- Keycloak: `profile: keycloak`、`oidc_sub`。Google 固有の `trust.personal_accounts` は
  設定しない。
- Microsoft Entra ID: `profile: entra`、`entra_oid_tid`。tenant を固定する `required_tid` が
  必須で、subject は token の `tid:oid`。email、UPN、表示名を永続 subject に使わない。

## 確認済み email による招待

IdP が確認済み email を返す場合、管理者は `user invite --idp <provider-id> --email <email>
--name <name>` で user と pending invitation を登録できる。対象 revision で
`trust.email_binding: verified_email_invitation` を使う場合、同じ provider と issuer の
招待に一致する verified email が初回 login で確認されると binding が作成される。
`disabled` では invitation は作成されても login で消費されない。

`allowed_email_domains` は invitation 消費時の追加条件であり、全 login の allowlist では
ない。既存 binding は provider、issuer、subject で解決される。未検証 email を本人確認に
使わず、Entra では管理者確認済み subject を明示的に bind できる。
[Entra user の登録](../guides/002-authctl.md#2-entra-user-を登録する) と
[bridge 構築](001-auth-bridge-setup.md#5-entra-application-と-client-secret) を参照する。

## 登録できないとき

IdP login の成功だけでは token は発行されない。provider ID、issuer、callback、tenant と
既存 binding を確認し、invitation を使う場合は email が IdP 上で verified として返ることを
確認する。未検証 email を強制的に信頼しない。IdP を使わない検証・障害時の手動発行は
[token 発行](../operations/005-token-flows.md)を参照する。
