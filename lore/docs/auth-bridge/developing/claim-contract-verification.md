# Lore JWT claim contract の検証

`lore-claimprobe` は、bridge が発行する Lore 用 JWT が、使用する `lore` と
`loreserver` に受け入れられるかを確認する開発用 CLI です。

通常の Entra ID 運用、ユーザー登録、repository 権限管理では使いません。Lore binary、
bridge の token 実装、または IdP 構成を変更して、JWT の互換性を確認する場合だけ使います。

この CLI は検証用の署名鍵と token を生成し、次を確認できます。

- issuer、audience、user subject、repository resource ID、permission
- 有効期限、署名鍵、JWKS
- 正しい repository と権限の token が許可されること
- 別 repository、期限切れ、audience 不一致、権限不足の token が拒否されること

```bash
cargo build -p lore-claimprobe
target/debug/lore-claimprobe keygen --out-dir .probe
target/debug/lore-claimprobe mint \
  --key .probe/probe-private.pem \
  --repository-id "<lore-repository-id>" \
  --permissions read,write \
  --out .probe/token.jwt \
  --print-login-command false
```

生成した token は credential です。`.probe/` をrepository、shell history、共有terminal、
CI logに残さないでください。

詳細な実行方法や判定ケースが必要になった場合は、`lore-auth-bridge` の
`lore-claimprobe --help` とソースのテストを参照します。
