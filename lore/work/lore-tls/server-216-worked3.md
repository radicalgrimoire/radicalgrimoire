# 3. Nginx の構築（TLS 版）

新規構築向けの未検証手順。worked1・2 の証明書と bridge が必要。
設定例は同じフォルダの `nginx.conf` を参照する。認証用 Nginx の HTTPS と
Lore Server gRPC の TLS は別の経路。
設定例の `http2 on;` には Nginx 1.25.1 以降が必要。

```bash
sudo apt-get install -y nginx
nginx -v
systemctl status nginx --no-pager -l
ss -lnt '( sport = :80 or sport = :8080 or sport = :8081 )'

sudo vim /etc/nginx/sites-available/lore-auth
```

設定例を参考に、証明書、秘密鍵、`grpc_ssl_trusted_certificate` とアクセス範囲を
環境に合わせる。Nginx は bridge gRPC の証明書を CA と `localhost` で検証する。
前段にプロキシを置く場合は接続元 IP の扱いを再検討する。

```bash
sudo ln -s /etc/nginx/sites-available/lore-auth \
  /etc/nginx/sites-enabled/lore-auth
sudo nginx -t
sudo systemctl reload nginx
ss -lnt '( sport = :80 or sport = :8080 or sport = :8081 )'
```

`nginx -t` が失敗した場合、修正して再確認してから reload する。

```bash
curl --noproxy '*' -i --max-time 10 \
  --cacert /datadrive/lore/certs/lore-ca.crt \
  --resolve 172.20.11.216:8080:127.0.0.1 \
  https://172.20.11.216:8080/healthz

printf '\000\000\000\000\000' | curl --noproxy '*' \
  --http2 -sS --max-time 10 \
  --cacert /datadrive/lore/certs/lore-ca.crt \
  --resolve 172.20.11.216:8081:127.0.0.1 \
  -H 'Content-Type: application/grpc' \
  -H 'TE: trailers' \
  --data-binary @- \
  --dump-header - \
  --output /dev/null \
  https://172.20.11.216:8081/epic_urc.UrcAuthApi/HealthCheck
```

Lore の認証設定と社内向けの待受設定は worked4 で追記・変更する。
