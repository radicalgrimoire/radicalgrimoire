# 管理者ユーザーの作成

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

先に [Lore Server の受入確認](../lore-server/005-acceptance.md#server-単体の確認)を完了する。
bridge host の管理者が、Entra ID と紐付けた管理 Web UI 用のユーザーを登録する。
招待は使用しない。複数人を登録する場合は、ユーザーごとに作成と紐付けを行う。

## 1. ユーザーを作成する

Entra 管理画面で管理者の email、display name、tenant ID、object ID を確認する。
まず既存 user を確認する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml user list
```

存在しない場合のみ、対象者の値に置き換えて作成する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user add --email "<ADMIN_EMAIL>" --name "<DISPLAY_NAME>"
```

## 2. Entra ID を紐付ける

管理者が確認した tenant ID と object ID を `<TENANT_ID>:<OBJECT_ID>` として指定する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user bind-identity --idp entra --email "<ADMIN_EMAIL>" \
  --subject "<TENANT_ID>:<OBJECT_ID>"
```

subject が別 user に bind 済みなら上書きせず、Entra 側と既存 binding を確認する。

## 3. 管理者として設定する

[bridge 設定](006-configuration.md)の `/opt/lore/config/lore-auth.yaml` で、
`admin.admin_emails` に作成したユーザーと同じ email を指定する。
複数の管理者を登録できる。既に設定済みの場合は重複させず、既存の管理者を消さない。

```yaml
admin:
  admin_emails:
    - "<ADMIN_EMAIL_1>"
    - "<ADMIN_EMAIL_2>"
```

各 email は手順 1 で作成したユーザーの email と一致させる。
既存の `admin` section を編集し、重複して追加しない。変更した場合は停止時間を調整し、
設定を確認して bridge を再起動する。

```bash
sudo systemctl restart lore-auth
systemctl is-active lore-auth
```

管理画面を利用する前に、[管理 endpoint の公開範囲](../../admin-webtools/README.md)を制限し、
[管理 Web UI のログイン](../../admin-webtools/001-login.md)を確認する。
管理画面の管理者設定だけでは repository 権限は付与されない。
一般ユーザーの登録と必要な repository 権限は [lore-authctl の利用者・権限管理](../../guides/002-authctl.md)を参照する。

次は [Windows CLI のインストール](../windows-cli-setup.md)。
導入後の確認は[セットアップの入口](../README.md#導入後)を参照する。
