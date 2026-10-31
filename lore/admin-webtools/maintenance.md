# 管理 UI: メンテナンスモード

[管理 UI にログイン](login.md)した管理者は Server settings 画面でメンテナンスモードを
設定できる。以下は bridge `b332e35` の文書に基づく概要であり、動作は使用する revision
によって異なる。一般化した操作の通し検証は未実施。

## 影響

メンテナンスモードの状態は再起動後も保持され、bridge server と `lore-authctl` の新規 token
発行を停止する。一方、**発行済み token は失効しない**。利用者への影響と token の有効期限を
確認してから設定する。

削除前待機時間は既定 15 分だが、対象 revision では強制されない。個別指定された token の期限や
Lore の期限判定の猶予も管理者が確認する。

## repository の認可 record

repository の認可 record を無効化するにはメンテナンスモードが必要である。ただし、無効化は
Lore 本体の repository 削除ではない。grant の扱いと UI での制限は
[repository の操作](repositories.md#認可-record-の無効化) を参照する。

設定変更後はメンテナンス状態と監査記録を確認する。
