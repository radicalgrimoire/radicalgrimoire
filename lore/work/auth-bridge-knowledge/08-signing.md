# JWT と署名鍵

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)、[バックアップ](../../operations/backup-recovery.md)（補足）  
**根拠:** [Signing Keys](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/signing-keys.md)、[Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#jwt)

## 統合文案

bridge は authn / authz token を RS256 で署名し、Lore Server は HTTP の JWKS から公開鍵を取得する。秘密鍵は `jwt.signing_key_dir` に保存され、DB には公開 JWK と鍵の metadata、秘密鍵 path が登録される。生成する key ID と `jwt.active_kid` を一致させ、秘密鍵を DB や JWKS に置かない。DB と鍵 directory は整合する recovery set に含める。

`jwt.issuer` と Lore Server の issuer、audience と remote host の整合性を確認する。元文書の authz token TTL は 15 分だが、対象 revision・発行方法によって確認する。鍵生成 command は revision で異なるため `--help` を確認し、既存鍵を安易に再生成しない。
