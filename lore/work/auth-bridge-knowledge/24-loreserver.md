# Lore Server の接続整合性

**統合先案:** [Lore Server 構築](../../setup/server-setup.md)（補足）  
**根拠:** [Loreserver](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/loreserver.md)

## 統合文案

Lore Server の `[environment.endpoint].auth_url` は bridge の gRPC TLS endpoint、`[server.auth.jwk].endpoint` は bridge HTTP の JWKS endpoint であり、互いに置き換えられない。`jwt_issuer` は bridge の issuer と一致させ、audience は `lore-service` と実際の remote host を含める構成を対象 revision で確認する。配布形態によっては environment TOML に加え `default.toml` が必要である。

元文書の対象 revision は起動時に JWKS と JWT 検証を初期化する。bridge の issuer、audience、署名鍵、JWKS または auth endpoint を変更した場合は bridge と Lore Server の再起動要否を確認し、認証と repository 操作まで検証する。
