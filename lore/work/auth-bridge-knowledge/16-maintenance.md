# メンテナンスと repository 無効化

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)（新規候補）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

対象 revision の管理 UI では、永続化されるメンテナンスモードを設定でき、server と authctl からの新規 token 発行を停止する。ただし発行済み token は失効しない。削除前待機時間は既定 15 分として設定できるが、現時点では強制されない。期限を個別指定した token や Lore の期限判定の猶予も管理者が確認する。

repository の認可 record の無効化にはメンテナンスモードが必要で、無効化時に grant は保持される。その後の確認操作で直接 grant を一括削除できるが、再有効化しても削除した grant は戻らない。この UI からの repository 削除は未対応であり、無効化は Lore 本体の削除ではない。CLI / ReBAC の削除は別の操作である。
