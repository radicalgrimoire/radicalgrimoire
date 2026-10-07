# LORE Server のアカウント管理

`172.20.12.193` の `lore-auth-bridge` における Entra user と repository grant の
管理手順をまとめる。Lore Server の構築は
[LORE Server の構築・運用](./lore-server.md) を参照する。

```bash
AUTHCTL=/home/mgs/lore-auth/bin/lore-authctl
AUTH_CONFIG=/home/mgs/lore-auth/lore-auth.yaml
```

## Entra user のオンボーディング

`onboard-entra-user.sh` は bridge account の作成、Entra identity binding、任意の
repository grant をまとめて行う。`--object-id` には Entra の Application ID ではなく、
対象ユーザーの **Object ID** を指定する。

```bash
/home/mgs/lore-auth/bin/onboard-entra-user.sh \
  --email new-user@gamestudio.co.jp \
  --name "New User" \
  --object-id <ENTRA-USER-OBJECT-ID> \
  --repo organization/repository \
  --role writer
```

repository 権限を後から付与する場合は、`--repo` と `--role` を省略できる。

```bash
/home/mgs/lore-auth/bin/onboard-entra-user.sh \
  --email new-user@gamestudio.co.jp \
  --name "New User" \
  --object-id <ENTRA-USER-OBJECT-ID>
```

bridge の `user add` は IdP identity を bind しない低レベル操作であるため、通常の
Entra user onboarding には使わない。

## アカウント一覧、無効化、再有効化

bridge のアカウントは hard delete せず、無効化してログインを止める。

```bash
"$AUTHCTL" --config "$AUTH_CONFIG" user list
"$AUTHCTL" --config "$AUTH_CONFIG" user disable user@gamestudio.co.jp
"$AUTHCTL" --config "$AUTH_CONFIG" user enable user@gamestudio.co.jp
```

## repository の権限を付与する

grant の subject は `user:<USER-UUID>` または `user:<EMAIL>` を使う。role は
`reader`、`writer`、`admin` である。`writer` は read を包含する。

```bash
"$AUTHCTL" --config "$AUTH_CONFIG" grant add \
  "user:<USER-UUID>" \
  "organization/repository" \
  reader

"$AUTHCTL" --config "$AUTH_CONFIG" grant add \
  "user:<USER-UUID>" \
  "organization/repository" \
  writer
```

repository create 後は、作成者に `writer` grant を明示的に付与する。現行の bridge では
repository resource の作成と作成者 grant の作成が別操作であり、自動付与されない場合がある。

## 権限を確認・取消する

```bash
"$AUTHCTL" --config "$AUTH_CONFIG" grant list
"$AUTHCTL" --config "$AUTH_CONFIG" grant list organization/repository

"$AUTHCTL" --config "$AUTH_CONFIG" check \
  user@gamestudio.co.jp \
  organization/repository \
  read
"$AUTHCTL" --config "$AUTH_CONFIG" check \
  user@gamestudio.co.jp \
  organization/repository \
  write
```

```bash
"$AUTHCTL" --config "$AUTH_CONFIG" grant remove \
  "user:<USER-UUID>" \
  "organization/repository" \
  writer
```
