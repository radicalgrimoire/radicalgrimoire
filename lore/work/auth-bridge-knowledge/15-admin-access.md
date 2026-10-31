# 管理 UI の直接・実効権限

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)（補足）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

repository の View access は直接 grant を表示するため、group 経由やサーバー管理者の暗黙の権限を直接 grant と混同しない。Users の直接 repository 権限編集は None / Reader / Writer / Admin を一括保存し、複数の既存 role は明示的に別の値を選ぶまで保持できる。表示後に直接 grant が別途変更された場合、保存は失敗する。変更と監査は同時に確定するが、発行済み token は無効化されない。

Server settings の check simulator で user、repository、action を評価し、表示される根拠は補助情報として扱う。最終的な判定は authorization policy の結果であり、実 client の動作も別途確認する。
