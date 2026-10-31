# 管理 UI: repository

[管理 UI にログイン](login.md)した管理者は Repositories 画面から repository を確認・管理
できる。以下は bridge `b332e35` の文書に基づく概要であり、画面や機能は revision によって
異なる。一般化した操作の通し検証は未実施。変更前に対象と影響を確認する。

## repository を見る

登録済み repository を一覧・検索できる。View access では user や group に対する直接 grant を
確認・追加・解除できる。group 経由やサーバー管理者の暗黙の権限は直接 grant の一覧とは区別する。

## repository を作る

Name と任意の Organization を指定して作成できる。指定時の名前は `Organization/Name` に
なる。各部分は半角英数字、`-`、`_`、`.` を使え、先頭の `.` は不可。ログイン中の管理者の
認証で Lore に repository と `main` branch を作成し、ReBAC に同期された認可 record を
確認して監査する。

この機能には対応する Lore Server と `lore.repository_create_url` が必要。HTTP は loopback
IP のみ使用でき、それ以外は信頼された certificate を持つ HTTPS を使う。Lore の作成、
bridge の同期、監査は一つの transaction ではない。結果不明や一部成功のときは、再試行前に
表示された repository ID で Lore と bridge の双方を確認する。

## 認可 record の無効化

repository の認可 record の無効化には [メンテナンスモード](maintenance.md) が
必要で、grant は保持される。その後の確認操作で直接 grant を一括削除できるが、再有効化しても
削除した grant は戻らない。

対象 revision の UI からの repository 削除は未対応であり、無効化は Lore 本体の削除ではない。
CLI / ReBAC の削除は別操作である。変更後は対象と監査記録を確認し、必要に応じて実 client でも
操作を確認する。
