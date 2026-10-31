# Entra application と client secret

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

Entra 管理者に Web application を作成してもらい、組織内 account に限定する。Web redirect
URI を `https://<SERVER_HOST>:8080/auth/entra/callback` とし、OpenID Connect の
`openid`、`profile`、`email` を設定する。

「Certificates & secrets」で client secret を発行し、**Secret ID ではなく Value** を
安全に保管する。Value は作成時以外には再表示できない。期限と更新担当者を記録し、値は
shell history、command 引数、ログ、chat に残さない。editor の一時ファイルや backup にも注意する。
新規構築時は Value を root 所有 file に保存する。

```bash
sudoedit /etc/lore/secrets/entra-client-secret
sudo chown root:lore /etc/lore/secrets/entra-client-secret
sudo chmod 0640 /etc/lore/secrets/entra-client-secret
```

service user の読み取りを確認し、server 上で Entra の token endpoint に接続して Secret を
検証する。source checkout の path、tenant ID、client ID は実環境に合わせる。Python 3 と
Entra への HTTPS 接続が必要。検証者は secret file を読み取れる必要がある。

```bash
sudo -u lore test -r /etc/lore/secrets/entra-client-secret
sudo bash "$HOME/src/lore-auth-bridge/scripts/verify-entra-client-secret.sh" \
  --tenant-id "<TENANT_ID>" \
  --client-id "<CLIENT_ID>" \
  --secret-file /etc/lore/secrets/entra-client-secret
```

この検証は Microsoft Graph 向け client credentials 要求の結果であり、Entra browser login
全体の成功は保証しない。失敗時は Secret の誤りだけでなく tenant / client ID、app 設定、
権限、ネットワークも確認する。Secret の更新時は新しい Value を別ファイルで検証し、
旧 Secret と復旧手段を確保してから置き換える。bridge は起動時に読み込むため、再起動後に
実際の login と Lore 操作を確認する。旧 Secret は切り替え成功まで失効させない。
更新用 file は制限された別 file に置いて検証し、同一 filesystem 上で原子的に置き換える。
所有権・権限と service user の読み取りを再確認し、失敗時に旧 file を復元できるようにする。

次は [bridge 設定](006-configuration.md)。
