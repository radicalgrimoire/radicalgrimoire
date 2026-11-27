# 216 の Nginx 設定

2026-11-09 に確認した `/etc/nginx/sites-available/lore-auth` の実機設定。
215 ベースの案ではなく、現在の 216 の設定を記録している。
8080 と 8081 は localhost と 216 の社内 IP で待ち受ける。

```nginx
server {
    listen 127.0.0.1:8080 ssl;
    listen 172.20.11.216:8080 ssl;
    server_name 172.20.11.216;

    allow all;

    ssl_certificate /datadrive/lore/certs/lore-server.crt;
    ssl_certificate_key /datadrive/lore/certs/lore-server.key;

    access_log off;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header x-lore-client-ip $remote_addr;
    }
}

server {
    listen 127.0.0.1:8081 ssl;
    listen 172.20.11.216:8081 ssl;
    http2 on;
    server_name 172.20.11.216;

    ssl_certificate /datadrive/lore/certs/lore-server.crt;
    ssl_certificate_key /datadrive/lore/certs/lore-server.key;

    access_log off;

    grpc_ssl_trusted_certificate /datadrive/lore/certs/lore-server.crt;
    grpc_ssl_verify on;
    grpc_ssl_server_name on;
    grpc_ssl_name localhost;

    location ^~ /ucs.auth.RebacApi/ {
        allow 127.0.0.1;
        allow 172.20.11.216;
        deny all;
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_pass grpcs://127.0.0.1:18081;
    }

    location / {
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_pass grpcs://127.0.0.1:18081;
    }
}
```

`/etc/systemd/system/nginx.service.d/override.conf`:

```ini
[Unit]
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive
```

## 社内クライアント向けの変更

- 8081 の待受に `172.20.11.216:8081` を追加した。
- HTTP と両方の gRPC location で、`x-lore-client-ip` を Nginx が接続元 IP で
  上書きするようにした。ReBAC location の許可範囲は変更していない。

前段に別のプロキシを置く場合は、接続元 IP の扱いを再検討する。
