# bridge の受入確認

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`<SERVER_HOST>` を置き換える。自己署名 certificate を指定し、TLS verification を有効にして
health と JWKS を確認する。DNS / TLS で CA 発行証明書を使う場合は `--cacert` に
`/opt/lore/certs/lore-ca.crt` を指定する。

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

nginx からの upstream と同じ `localhost` 名で bridge gRPC の証明書を検証する。
CA 発行証明書の場合は `-CAfile` を CA 証明書に変更する。

```bash
openssl s_client -connect 127.0.0.1:18081 \
  -CAfile /opt/lore/certs/lore-server.crt -verify_hostname localhost \
  -verify_return_error -brief </dev/null
```

両 service が `enabled` / `active`、health が `ok`、JWKS が応答し、public と loopback の
listener が想定どおりであることを確認する。HTTP health の成功だけでは gRPC の動作や
client の trust は確認できない。

続けて [Lore Server](../lore-server/README.md) を構築し、[管理者ユーザーの作成](010-admin-user-setup.md)に進む。
