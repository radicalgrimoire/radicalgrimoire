# Identity Provider と招待

bridge は IdP が認証した external identity を登録済み user と照合する。以下は
bridge `a751711` の実装と旧文書に基づく説明であり、設定 schema、対象 binary と IdP の挙動を
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

bridge `a751711` では、**管理 Web UI の招待画面と `/admin/users/invite` は削除済み**だが、
`lore-authctl user invite` と初回 login 時の招待による binding は残っている。
招待機能全体が削除されたわけではない。CLI で作成する pending invitation は bridge 内の
identity binding 予約であり、この説明はメール送信機能を意味しない。

IdP が確認済み email を返す場合、管理者は `user invite --idp <provider-id> --email <email>
--name <name>` で user と pending invitation を登録できる。対象 revision で
`trust.email_binding: verified_email_invitation` を使う場合、同じ provider と issuer の
招待に一致する verified email が初回 login で確認されると binding が作成される。
`disabled` では invitation は作成されても login で消費されない。
`trust.email_binding` を省略した場合、対象 revision の既定値は `disabled` である。

`allowed_email_domains` は invitation 消費時の追加条件であり、全 login の allowlist では
ない。既存 binding は provider、issuer、subject で解決される。未検証 email を本人確認に
使わず、Entra では管理者確認済み subject を明示的に bind できる。
[CLI での招待操作](../../guides/002-authctl.md#確認済み-email-による招待)、
[Entra user の登録](../../guides/002-authctl.md#2-entra-user-を登録する) と
[bridge 構築](005-entra.md) を参照する。

実装上の根拠は [CLI の招待処理](https://github.com/radicalgrimoire/lore-auth-bridge/blob/a751711/crates/lore-authctl/src/commands/user.rs)、
[SQLite の login 解決](https://github.com/radicalgrimoire/lore-auth-bridge/blob/a751711/crates/lore-auth-adapters/src/sqlite/accounts.rs)、
[管理 UI の招待 route が存在しないことを確認するテスト](https://github.com/radicalgrimoire/lore-auth-bridge/blob/a751711/crates/lore-auth-inbound/tests/httpserver.rs)。

## 登録できないとき

IdP login の成功だけでは token は発行されない。provider ID、issuer、callback、tenant と
既存 binding を確認し、invitation を使う場合は email が IdP 上で verified として返ることを
確認する。未検証 email を強制的に信頼しない。IdP を使わない検証・障害時の手動発行は
[token 発行](../../operations/005-token-flows.md)を参照する。
