# bridge の受入確認

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`<SERVER_HOST>` を置き換える。自己署名 certificate を指定し、TLS verification を有効にして
health と JWKS を確認する。

```bash
systemctl is-enabled lore-auth nginx
systemctl is-active lore-auth nginx
sudo nginx -t
sudo ss -lntup | grep -E ':(8080|8081|18080|18081)\b'
curl --fail --cacert /opt/lore/certs/lore-server.crt \
  https://<SERVER_HOST>:8080/healthz
curl --fail --cacert /opt/lore/certs/lore-server.crt \
  https://<SERVER_HOST>:8080/.well-known/jwks.json
sudo journalctl -u lore-auth -n 100 --no-pager
```

両 service が `enabled` / `active`、health が `ok`、JWKS が応答し、public と loopback の
listener が想定どおりであることを確認する。HTTP health の成功だけでは gRPC の動作や
client の trust は確認できない。

続けて [Lore Server](../lore-server/README.md) を構築し、[利用者登録](010-user-onboarding.md) に進む。
