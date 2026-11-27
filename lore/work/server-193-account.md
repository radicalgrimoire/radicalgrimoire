# 172.20.12.193: Lore アカウントの作成

この手順は、`172.20.12.193` の Lore Server を利用する Microsoft Entra ID
ユーザーを `lore-auth-bridge` に登録し、repository へのアクセス権を付与するための
運用手順です。

Lore のローカル password account は作成しません。Entra ID を本人確認の認証元とし、
bridge にユーザー identity と repository 権限を登録します。

## 事前条件

- 管理者が `mgs@172.20.12.193` に SSH 接続できる。
- `lore-auth-bridge` と Lore Server が起動している。
- 対象者が Entra tenant に存在する。
- 対象 repository が Lore Server に登録済みである。

bridge endpoint を確認します。

```bash
curl -fk https://172.20.12.193:8080/healthz
curl -fk https://172.20.12.193:8080/.well-known/jwks.json
```

どちらかが失敗する場合、アカウントを作成せずに bridge の起動状態と network
configuration を確認します。

## 用意する情報

Entra 管理センターで対象ユーザーを開き、次の情報を確認します。

| 項目 | 例 | 用途 |
| --- | --- | --- |
| Email address | `alice@example.com` | bridge user の識別 |
| Display name | `Alice Example` | 表示名 |
| Object ID | `11111111-2222-3333-4444-555555555555` | Entra identity binding |
| Repository | `gamestudio/UnrealEngine` | 権限を付与する対象 |
| Role | `reader`、`writer`、`admin` | repository 権限 |

通常の開発利用者には `writer` を付与します。`admin` は repository の管理が必要な
利用者にだけ付与してください。

> [!IMPORTANT]
> Entra の email claim は `email_verified=false` になる場合があります。そのため
> この環境では email invitation だけに依存せず、Entra の Object ID を明示して
> identity binding を作成します。

## アカウントを作成して権限を付与する

1. 管理者としてサーバーに接続します。

   ```bash
   ssh mgs@172.20.12.193
   ```

2. `lore-authctl` と既存 account を確認します。

   ```bash
   /home/mgs/lore-auth/bin/lore-authctl \
     --config /home/mgs/lore-auth/lore-auth.yaml \
     user list
   ```

3. bridge user を作成します。

   ```bash
   /home/mgs/lore-auth/bin/lore-authctl \
     --config /home/mgs/lore-auth/lore-auth.yaml \
     user add \
     --email "alice@example.com" \
     --name "Alice Example"
   ```

   email がすでに `user list` に存在する場合、この command は実行しません。

4. Entra subject `<tenant-id>:<object-id>` を bridge user に bind します。

   ```bash
   /home/mgs/lore-auth/bin/lore-authctl \
     --config /home/mgs/lore-auth/lore-auth.yaml \
     user bind-identity \
     --idp entra \
     --email "alice@example.com" \
     --subject "<tenant-id>:11111111-2222-3333-4444-555555555555"
   ```

   対象の Entra subject が別の bridge user にすでに紐付いている場合、command は拒否
   されます。この場合は binding を変更せず、対象の Entra Object ID と既存 account を
   確認します。

5. repository 権限を付与します。

   ```bash
   /home/mgs/lore-auth/bin/lore-authctl \
     --config /home/mgs/lore-auth/lore-auth.yaml \
     grant add \
     "user:alice@example.com" \
     "gamestudio/UnrealEngine" \
     writer
   ```

   既存 grant を確認する場合は、先に次を実行します。

   ```bash
   /home/mgs/lore-auth/bin/lore-authctl \
     --config /home/mgs/lore-auth/lore-auth.yaml \
     grant list "gamestudio/UnrealEngine"
   ```

6. 登録結果を確認します。

   ```text
   <user-id>    alice@example.com    Alice Example
   ```

identity だけを登録する場合は、手順 5 を省略します。

## 登録結果を確認する

bridge の認可判定で、付与した権限を確認します。

```bash
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  check "alice@example.com" "gamestudio/UnrealEngine" write
```

`writer` を付与した場合は `allow` が返る必要があります。必要に応じて登録済み user
と grant も確認します。

```bash
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  user list

/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  grant list "gamestudio/UnrealEngine"
```

## 利用者に依頼する初回ログイン

利用者は、管理者から配布された `grpc.crt` を Windows の「信頼されたルート証明機関」
に import してから、PowerShell で次を実行します。

```powershell
lore auth login lore://172.20.12.193:41337
```

表示された browser で、登録した Entra account を使って sign in します。login 後は
対象 repository の clone と push で、認証と `writer` 権限の両方を確認してください。

```powershell
lore clone lore://172.20.12.193:41337/gamestudio/UnrealEngine .\UnrealEngine
```

## 関連資料

- [Lore Server 導入記録](./server-215.md)
