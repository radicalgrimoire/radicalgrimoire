# 管理 UI の Entra 登録

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)（補足）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

`entra_oid_tid` provider を設定した対象 revision では、管理 UI の Users から email、表示名、確認済み Object ID を指定して user 作成と identity binding を一括実行できる。保存 subject は設定済み `required_tid` と Object ID の組み合わせで、変更と監査は同一 transaction で確定する。

既存 binding の tenant / object ID は Users の access 画面で表示・修正できるが、表示値は保存済み binding であり Entra への照会結果ではない。変更は次回以降の login に適用され、既存 session や token は無効化されない。操作前に対象 identity を Entra 側で照合する。
