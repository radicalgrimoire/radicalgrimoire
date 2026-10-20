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

2. 運用スクリプトが利用可能であることを確認します。

   ```bash
   test -x /home/mgs/lore-auth/bin/onboard-entra-user.sh
   ```

3. 対象者の email、表示名、Entra Object ID、repository、role を指定して実行します。

   ```bash
   /home/mgs/lore-auth/bin/onboard-entra-user.sh \
     --email "alice@example.com" \
     --name "Alice Example" \
     --object-id "11111111-2222-3333-4444-555555555555" \
     --repo "gamestudio/UnrealEngine" \
     --role writer
   ```

   このスクリプトは、次を実行します。

   1. email に対応する bridge user がなければ作成する。
   2. Entra subject `<tenant-id>:<object-id>` を user に bind する。
   3. 指定 repository に指定 role の grant がなければ追加する。

   同じユーザー、identity binding、grant に対する再実行は安全です。別の user に
   すでに紐付いている Entra subject は拒否されます。

4. 実行結果に、次のように user と grant が表示されることを確認します。

   ```text
   Entra user ready: alice@example.com (<tenant-id>:<object-id>)
   Repository grant: gamestudio/UnrealEngine writer
   ```

repository 権限を後から付ける場合は、同じコマンドを `--repo` と `--role` を指定して
再実行します。identity だけを登録する場合は `--repo` を省略します。

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
- [Microsoft Entra ID](../docs/auth-bridge/setup/entra-id.md)
- [Authctl](../docs/auth-bridge/setup/authctl.md)
- [Entra ID 連携の変更根拠と検証記録](../docs/auth-bridge/setup/entra-id-integration-evidence.md)
