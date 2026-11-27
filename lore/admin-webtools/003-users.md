# 管理 UI: user

[管理 UI にログイン](001-login.md)した管理者は Users 画面から user を確認・管理できる。
以下は bridge `b332e35` の文書に基づく概要であり、画面や機能は revision によって異なる。
一般化した操作の通し検証は未実施。変更前に対象と影響を確認する。

## user を見る・登録する

user の一覧・検索、追加、無効化ができる。access 画面では表示名や repository への直接権限を
確認・変更できる。直接追加した user は login binding を持たない。

`entra_oid_tid` provider が設定されている場合は、email、表示名、Entra Object ID を指定し、
user の作成と identity binding を監査とともに一括確定できる。操作前に Entra 側で本人と ID を
照合する。subject は設定済み `required_tid` と Object ID の組み合わせになる。

access 画面では保存済みの tenant / object ID を確認・修正できるが、表示値は Entra への
照会結果ではない。変更は次回以降の login に反映され、既存 session と token は無効化されない。

## 直接 repository 権限を変更する

access 画面で repository ごとに None / Reader / Writer / Admin を選び、一括保存できる。
複数の既存 role は別の値を選ぶまで保持できる。group やサーバー管理者権限による実効権限は
別に確認し、このフォームの直接 grant と混同しない。

表示後に直接 grant が別途変更された場合、保存は失敗する。変更と監査は同時に確定するが、
発行済み token は無効化されない。`admin` は lock 解除以外の操作も許可する可能性があるため、
信頼できる対象に限定する。変更後は対象と監査記録を確認し、必要に応じて実 client でも確認する。
