# nested group の移行

**統合先案:** [更新](../../operations/upgrade.md)、[authctl 操作](../../operations/authctl.md)（補足）  
**根拠:** [Authctl](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/authctl.md#group-nest-remove)、[migration test](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/crates/lore-auth-adapters/tests/sqlite.rs)

## 統合文案

対象 revision では管理 UI / CLI から nested group を新規作成できない。`phase7_remove_existing_group_nests_20261030` migration は server または authctl が DB を開く際に既存の group 間所属を一度解除し、監査に記録する。残存する関係は管理 UI または `group nest remove` で解除できる。

更新前に DB を backup し、継承していた repository grant と service account の許可 CIDR を洗い出し、必要な直接所属・権限を計画する。発行済み token は取り消されない。元の Configuration の「nested group を含む」説明は評価機構の説明であり、現行の管理・migration と混同しない。対象 revision に同じ migration があることを事前に確認する。
