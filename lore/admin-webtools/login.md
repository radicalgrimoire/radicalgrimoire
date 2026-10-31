# 管理 Web UI にログインする

bridge の管理者が、許可された端末から管理 UI にアクセスする手順。
この一般化した手順は実環境で通し検証していない。画面と応答は使用する bridge revision に
よって異なる。

## ログイン前の確認

- [管理 UI の設定](README.md)に従い、管理 endpoint の公開範囲を制限し、
  `admin.admin_emails` に管理者の email を設定している。
- 管理者の有効な bridge user と IdP identity が登録済みで、ブラウザーから login できる。
  Entra の email claim が未検証の場合は、invitation だけに頼らず
  [identity binding](../guides/authctl.md#2-entra-user-を登録する) を確認する。

対象 revision では login 後も、有効 user の正規化済み email が管理者一覧と一致する必要が
ある。管理 UI の管理者であることと repository の権限は別である。

## ログイン

1. 許可された管理端末で、構築環境の OIDC login flow から Entra ID などの IdP に
   サインインする。
2. 同じ browser session で `https://<SERVER_HOST>:8080/admin` を開く。
   host と port は実際の bridge HTTP 公開 URL に置き換える。
3. 管理画面が表示されること、非管理者や許可外 network から管理操作できないことを確認する。
   対象 revision では未ログインの `/admin` GET は login に redirect されるため、UI の
   有効化自体は外部から判別できる。非管理者や許可外 peer は 404 を返す。

表示できない場合は公開制限を解除せず、管理者 email、user の状態と binding、IdP、
network、service log を確認する。ログに secret や token を含めない。

ログイン後に利用できる機能は [管理 UI のドキュメント一覧](README.md#ドキュメント) を参照する。
