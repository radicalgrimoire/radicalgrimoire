# アカウントとrepository権限の管理

Microsoft Entra IDの利用者をbridgeに登録し、Lore repositoryへの権限を付与する運用手順です。
`lore-authctl` のすべてのコマンドは [Authctl](authctl.md) を参照してください。

## 事前条件

- `lore-auth-bridge` と `loreserver` が起動している。
- 対象者が設定済みのEntra tenantに存在する。
- 対象repositoryがLore Serverに登録済みである。
- 管理者がbridgeの設定ファイルと `lore-authctl` を利用できる。

## 利用者を招待する

通常のEntra IDオンボーディングでは、emailを指定してpending invitationを作成します。

```bash
lore-authctl --config /path/to/lore-auth.yaml user invite \
  --idp entra \
  --email "user@example.com" \
  --name "User Name"
```

利用者が `lore auth login <remote-url>` を実行してEntra IDにログインすると、bridgeは
verified emailとinvitationを照合し、Entra subjectをbridge userへbindします。招待されて
いないユーザーにはtokenを発行しません。

Entra IDで取得するsubjectは `tid:oid` です。email、UPN、`preferred_username` を
永続identityの識別子として使いません。

## repository権限を付与する

対象userに `reader`、`writer`、または `admin` のgrantを付与します。`writer` はreadを
包含します。

```bash
lore-authctl --config /path/to/lore-auth.yaml grant add \
  "user:<USER-UUID>" \
  "organization/repository" \
  writer
```

repository作成後は、作成者に `writer` grantが付与されていることを確認します。repository
resourceの作成と作成者grantの作成は別操作になる場合があります。

## 確認、無効化、取消

```bash
lore-authctl --config /path/to/lore-auth.yaml user list
lore-authctl --config /path/to/lore-auth.yaml grant list organization/repository

lore-authctl --config /path/to/lore-auth.yaml check \
  user@example.com \
  organization/repository \
  write

lore-authctl --config /path/to/lore-auth.yaml user disable user@example.com
lore-authctl --config /path/to/lore-auth.yaml user enable user@example.com

lore-authctl --config /path/to/lore-auth.yaml grant remove \
  "user:<USER-UUID>" \
  "organization/repository" \
  writer
```

`check` が `allow` を返し、利用者がlogin後にrepositoryをcloneまたはpushできれば、認証と
権限付与は完了です。
