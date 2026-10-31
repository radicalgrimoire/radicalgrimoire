# repository と grant の識別

**統合先案:** [authctl 操作](../../operations/authctl.md)（補足）  
**根拠:** [Authctl](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/authctl.md#repo-add)、[Loreserver](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/loreserver.md#environmentendpoint)

## 統合文案

通常は Lore Server の ReBAC `CreateResource` により bridge に repository が登録される。grant は user または group に対する repository 単位の `reader`、`writer`、`admin` role であり、JWT の `resources[].resource_id` は repository 名ではなく `urc-{lore_repository_id}` である。

`admin` は他人の lock 解除以外の操作も許可する可能性があるため、信頼できる主体に限定する。grant の変更は既に発行された authz token を直ちに無効化しない。変更後は新しい認可情報を取得し、対象 revision で実際の権限を確認する。
