# Lore JWT claim contract の検証

`lore-claimprobe` は、`lore-auth-bridge` が発行する JWT の claim が、使用する
`lore` と `loreserver` の期待する形式に一致するかを確認する開発用 CLI です。

通常の bridge 導入、ユーザー登録、repository 権限管理では使いません。Lore binary または
bridge の token 実装を更新するときだけ実行します。

## 確認対象

この CLI では、次のような JWT claim を確認できます。

- issuer と audience
- user subject、表示名、group、IdP
- repository resource ID
- `read`、`write`、`admin` permission
- token の有効期限
- JWT signing key と JWKS

## build

repository root で実行します。

```bash
cargo build -p lore-claimprobe
target/debug/lore-claimprobe --help
```

Windows では次を実行します。

```powershell
cargo build -p lore-claimprobe
.\target\debug\lore-claimprobe.exe --help
```

## JWT を作成して内容を確認する

検証専用の key と JWKS を作成します。出力先には private key が含まれるため、repository に
追加してはいけません。

```bash
target/debug/lore-claimprobe keygen --out-dir .probe
```

次に、指定 repository 用の短命 token を file に出力します。`--out` を指定すると token
本体を terminal に表示しません。

```bash
target/debug/lore-claimprobe mint \
  --key .probe/probe-private.pem \
  --repository-id 0194b726b34e72b0b45550b88a967076 \
  --permissions read,write \
  --out .probe/token.jwt \
  --print-login-command false
```

token の header と payload を確認します。

```bash
target/debug/lore-claimprobe decode < .probe/token.jwt
```

`decode` は署名を検証しません。claim の内容を表示するための診断コマンドです。

## Lore binary との互換性を確認する

検証対象の Lore binary に合わせて、issuer、audience、repository ID、remote URL、auth URL を
明示します。生成した token を `lore auth login --token-type lore` に渡し、対象
repository への read / write が期待どおり許可または拒否されることを確認します。

```bash
target/debug/lore-claimprobe mint \
  --key .probe/probe-private.pem \
  --issuer "https://auth.example.com" \
  --audience "lore-service,172.20.12.193" \
  --repository-id "<lore-repository-id>" \
  --auth-url "https://172.20.12.193:8081" \
  --remote-url "lore://172.20.12.193:41337/<repository>" \
  --out .probe/token.jwt \
  --print-login-command false
```

検証用 token は credential です。終了後に `.probe/` を安全な場所へ移動または削除し、
shell history、共有 terminal、CI log に token を残さないでください。

## ケース別 token を生成する

`matrix` は、正常・異常系の token をまとめて生成します。

```bash
target/debug/lore-claimprobe matrix \
  --out-dir .probe/matrix \
  --repository-id "<lore-repository-id>" \
  --wrong-repository-id "<different-lore-repository-id>" \
  --remote-url "lore://172.20.12.193:41337"
```

次のケースを含みます。

- wildcard resource
- 対象 repository と一致する resource
- 別 repository の resource
- resource がない token
- expired token
- remote audience がない token
- read-only token

期待する許可・拒否の結果は、使用する Lore binary の claim contract に基づいて判定します。
更新前後で同じ matrix を実行し、結果が意図せず変わっていないことを確認してください。
