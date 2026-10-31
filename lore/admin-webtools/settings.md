# 管理 UI: Server settings

[管理 UI にログイン](login.md)した管理者は Server settings 画面から権限判定の確認、
Service Account 作成、メンテナンスの設定ができる。以下は bridge `b332e35` の文書に基づく
概要であり、画面や機能は revision によって異なる。一般化した操作の通し検証は未実施。
管理 UI 自体の公開範囲と管理者の設定は [管理 UI の設定](README.md) を参照する。

## 権限の判定を試す

check simulator で user、repository、action を指定し、設定済み authorization policy の
判定を確認できる。表示される grant などの根拠は補助情報である。判定結果に加え、実 client
の login や repository 操作も確認する。

## Service Account を作る

Client ID、表示名、既存 group を指定して Service Account を作成できる。account、所属、
監査は一括確定する。Client Secret は作成結果に一度だけ表示されるため、安全な credential
store に保存する。紛失時は対象 revision の `service-account rotate` で再発行する。

フォームは repository grant と CIDR を設定しない。別途設定し、
[runner からの login と clone](../operations/ci-service-account.md) を確認する。token や
secret をログや問い合わせに添付しない。

## メンテナンス

Server settings でメンテナンスモードを設定できる。影響と注意事項は
[メンテナンスモード](maintenance.md) を参照する。
