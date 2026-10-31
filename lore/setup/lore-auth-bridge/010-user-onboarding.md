# 利用者登録と repository へのアクセス

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

Entra の対象者について email、display name、tenant ID、object ID を管理者が確認する。
`user list` で既存 user を確認し、まだ存在しない場合は作成する。email は例を置き換える。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml user list
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user add --email "<USER_EMAIL>" --name "<DISPLAY_NAME>"
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  user bind-identity --idp entra --email "<USER_EMAIL>" \
  --subject "<TENANT_ID>:<OBJECT_ID>"
```

subject が別 user に bind 済みなら上書きせず、Entra 側と既存 binding を確認する。
[Lore Server](../lore-server/README.md) の構築後に対象 repository が作成・登録済みであることを確認し、必要な最小 role を付与する。
以下は `writer` の例である。

```bash
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  grant add "user:<USER_EMAIL>" "<REPOSITORY>" writer
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  check "<USER_EMAIL>" "<REPOSITORY>" write
```

`check` が `allow` となることを確認し、利用者の Windows client から実際に login と clone
を行う。repository の作成手順と CLI の互換性は使用する revision に合わせて確認する。
CI の login や writer 操作は別途実行して確認する。

次は [導入後](011-post-deployment.md)。
