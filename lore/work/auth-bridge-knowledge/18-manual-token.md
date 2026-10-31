# 手動 token 発行

**統合先案:** [authctl 操作](../../operations/authctl.md)（新規候補）  
**根拠:** [Authctl](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/authctl.md#token-mint-authn)

## 統合文案

IdP を使わない検証や障害時には、管理者が登録済み user の authn token を `token mint-authn` で発行できる。対象 revision では `--out <path>` を指定すると token は mode `0600` の file に保存され、token 本文と token 入り command は表示されない。指定しない場合は stdout に出力される。`--print-login-command` を使うと token を含む command が表示されるため、共有 terminal や CI log に残さない。

`token mint` は repository scoped authz token を手動発行する別操作である。token は credential として保存、転送、期限、廃棄を管理し、対象 binary の help で引数を確認する。
