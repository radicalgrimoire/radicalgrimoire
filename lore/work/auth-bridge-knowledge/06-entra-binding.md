# Entra identity の明示的な binding

**統合先案:** [authctl 操作](../../operations/authctl.md)（補足）  
**根拠:** [Entra 連携の根拠](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id-integration-evidence.md)

## 統合文案

Entra の `entra_oid_tid` は ID token の tenant ID と object ID を `<tenant-id>:<object-id>` として保存し、`required_tid` と一致しない tenant を拒否する。管理者は Entra 管理画面で対象 user と object ID を確認し、既存の有効な bridge user へ `user bind-identity` で結び付ける。email、UPN、表示名を永続 subject の代わりにしない。

同じ有効 user への同じ binding の再実行は冪等だが、別 user に紐付く subject や無効 user への binding は拒否される。identity 更新と監査の書き込みは同一 transaction で確定する。過去の onboarding script は削除済みであり、現行手順に含めない。
