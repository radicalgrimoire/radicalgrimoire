# 管理 UI: group

[管理 UI にログイン](login.md)した管理者は Groups 画面から group を確認・管理できる。
以下は bridge `b332e35` の文書に基づく概要であり、画面や機能は revision によって異なる。
一般化した操作の通し検証は未実施。変更前に対象と影響を確認する。

## group と member を見る

group を一覧表示し、View access から直接所属する member の検索、追加、解除ができる。
group に対する repository の直接 grant は [Repositories 画面](repositories.md#repository-を見る)
から確認・管理する。

## 許可接続元を管理する

View access で許可接続元 IP / CIDR の一覧・追加・解除ができる。適用される group の CIDR は
合算され、適用 CIDR がない通常 user の login には IP 制限がない。一方、Service Account の
認証には一致する CIDR が必要である。変更は発行済み token を無効化しない。

対象 revision は nested group を新規作成できない。既存の group 間所属の migration と
更新前の確認事項は [更新手順](../operations/upgrade.md#1-更新前の確認) を参照する。
変更後は対象と監査記録を確認し、必要に応じて実 client でも確認する。
