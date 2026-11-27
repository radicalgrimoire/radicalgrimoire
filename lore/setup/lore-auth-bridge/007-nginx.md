# nginx 設定

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/etc/nginx/sites-available/lore-auth` を作成し、`<SERVER_HOST>`、`<LISTEN_IP>` と `<SERVER_IP>` を
置き換える。`<SERVER_IP>` には Lore Server が nginx に接続するときの実際の送信元 IP を使う。
`<LISTEN_IP>` は待受インターフェースの社内 IP。ReBAC API は必要な caller だけに許可する。
`http2 on;` は nginx 1.25.1 以降が必要。

```nginx
server {
    listen 127.0.0.1:8080 ssl;
    listen <LISTEN_IP>:8080 ssl;
    server_name <SERVER_HOST>;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;
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
    listen <LISTEN_IP>:8081 ssl;
    http2 on;
    server_name <SERVER_HOST>;

    ssl_certificate /opt/lore/certs/lore-server.crt;
    ssl_certificate_key /opt/lore/certs/lore-server.key;
    access_log off;
    grpc_ssl_trusted_certificate /opt/lore/certs/lore-server.crt;
    grpc_ssl_verify on;
    grpc_ssl_server_name on;
    grpc_ssl_name localhost;

    location ^~ /ucs.auth.RebacApi/ {
        allow 127.0.0.1;
        allow <SERVER_IP>;
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

上記は 216 の自己署名証明書を trust anchor とする例。DNS / TLS の CA 発行証明書では
`grpc_ssl_trusted_certificate` を `/opt/lore/certs/lore-ca.crt` に変更し、
bridge の証明書に `DNS:localhost` が含まれることを確認する。
`x-lore-client-ip` は nginx が接続元で上書きする。bridge 側で loopback の trusted
proxy からの metadata のみを受け付ける構成を確認する。前段に proxy がある場合は
接続元と trust boundary を再設計する。

`RebacApi` は Lore Server 用である。proxy の背後では bridge が直接見る peer は proxy
なので、上記のように edge でも実際の
Lore Server 送信元を制限し、許可・拒否の両方を検証する。

実機の設定例は access log を無効にしている。ログ共有前には機密情報が含まれないことを確認する。
ログインや device flow の rate limit は上記の例では設定していない。
公開前に network boundary での制限と合わせて別途設計・検証する。

```bash
sudo ln -s /etc/nginx/sites-available/lore-auth /etc/nginx/sites-enabled/lore-auth
sudo nginx -t
```

既存 nginx site は削除しない。port が競合する場合は既存 configuration を確認して解決する。

次は [systemd と初期化](008-systemd.md)。
