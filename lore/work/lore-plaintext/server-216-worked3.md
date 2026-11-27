# nginx
sudo apt-get install nginx


systemctl status nginx --no-pager -l
ss -lnt '( sport = :80 or sport = :8080 or sport = :8081 )'


# 設定例は同じフォルダの nginx.md を参照。
sudo vim /etc/nginx/sites-available/lore-auth

sudo ln -s /etc/nginx/sites-available/lore-auth \
  /etc/nginx/sites-enabled/lore-auth

  sudo nginx -t


systemctl reload nginx
ss -lnt '( sport = :80 or sport = :8080 or sport = :8081 )'

curl --noproxy '*' -i --max-time 10 \
  --cacert /datadrive/lore/certs/lore-server.crt \
  --resolve 172.20.11.216:8080:127.0.0.1 \
  https://172.20.11.216:8080/healthz

printf '\000\000\000\000\000' | curl --noproxy '*' \
  --http2 -sS --max-time 10 \
  --cacert /datadrive/lore/certs/lore-server.crt \
  --resolve 172.20.11.216:8081:127.0.0.1 \
  -H 'Content-Type: application/grpc' \
  -H 'TE: trailers' \
  --data-binary @- \
  --dump-header - \
  --output /dev/null \
  https://172.20.11.216:8081/epic_urc.UrcAuthApi/HealthCheck


# 以下は worked4 で追記する設定。二重に追記しない。
[environment.endpoint]
auth_url = "https://172.20.11.216:8081"

[server.auth]
jwt_issuer = "https://172.20.11.216:8080"
jwt_audience = ["lore-service", "172.20.11.216"]

[server.auth.jwk]
endpoint = "http://127.0.0.1:18080/.well-known/jwks.json"