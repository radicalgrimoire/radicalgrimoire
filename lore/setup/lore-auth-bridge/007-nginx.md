# nginx 設定

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/etc/nginx/sites-available/lore-auth` を作成し、`<SERVER_HOST>` と `<SERVER_IP>` を
置き換える。`<SERVER_IP>` には Lore Server が nginx に接続するときの実際の送信元 IP を使う。
ReBAC API は必要な caller だけに許可する。

```nginx
server {
    listen 8080 ssl;
    server_name <SERVER_HOST>;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 8081 ssl;
    http2 on;
    server_name <SERVER_HOST>;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;

    location ^~ /ucs.auth.RebacApi/ {
        allow 127.0.0.1;
        allow <SERVER_IP>;
        deny all;
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }

    location / {
        grpc_set_header x-lore-client-ip $remote_addr;
        grpc_ssl_verify off;
        grpc_pass grpcs://127.0.0.1:18081;
    }
}
```

`grpc_ssl_verify off` は nginx から loopback 上の自己署名 gRPC endpoint への upstream
verification のみを無効にする。外部 client の TLS verification は無効化しない。
`x-lore-client-ip` は実機で Service Account 対応時に追加した設定である。bridge 側で
loopback の trusted proxy からの metadata のみを受け付ける構成を確認する。

`RebacApi` は Lore Server の resource lifecycle sync 用であり、stock Lore Server の
ReBAC client は service token metadata を送らないと旧資料に記録されている。
`rebac_allowed_peer_cidrs` が空の場合、対象 revision は loopback peer のみを許可する。
proxy の背後では bridge が直接見る peer は proxy なので、上記のように edge でも実際の
Lore Server 送信元を制限し、許可・拒否の両方を検証する。

公開される `/api/device/start`、`/api/device/token`、`/auth/{provider}/start` と
gRPC `/epic_urc.UrcAuthApi/StartAuthSession` は edge 側でも rate limit する。
bridge の per-peer 制限は多層防御であり、proxy の背後では edge の代替にならない。
proxy access log では OAuth code、device user code、login session nonce、token を含む
query string や機密 path を除外または redact し、ログ共有前にも機密情報を確認する。

```bash
sudo ln -s /etc/nginx/sites-available/lore-auth /etc/nginx/sites-enabled/lore-auth
sudo nginx -t
```

既存 nginx site は削除しない。port が競合する場合は既存 configuration を確認して解決する。

次は [systemd と初期化](008-systemd.md)。
