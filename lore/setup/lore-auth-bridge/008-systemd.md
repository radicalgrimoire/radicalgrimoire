# systemd と初期化

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/etc/systemd/system/lore-auth.service`:

```ini
[Unit]
Description=Lore authentication bridge
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive

[Service]
Type=simple
User=lore
Group=lore
WorkingDirectory=/opt/lore
ExecStart=/opt/lore/bin/lore-auth-server --config /opt/lore/config/lore-auth.yaml
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/datadrive/lore/auth

[Install]
WantedBy=multi-user.target
```

`RequiresMountsFor` は mount dependency を設定するが、意図した device が mount されているかの
確認の代わりにはならない。

起動前に、bridge が公開 CA による Entra と Lore 側の CA の両方を信頼できるようにする。
社内 IP の自己署名例では、OS CA bundle と自己署名公開証明書の両方を含む
専用 trust bundle を新規に用意する。既存 bundle は上書きしない。

```bash
sudo bash -c 'set -o noclobber; cat /etc/ssl/certs/ca-certificates.crt /opt/lore/certs/lore-server.crt > /opt/lore/certs/lore-auth-trust-bundle.pem'
sudo chown root:lore /opt/lore/certs/lore-auth-trust-bundle.pem
sudo chmod 0640 /opt/lore/certs/lore-auth-trust-bundle.pem
```

作成が失敗した場合は原因を確認し、先に進まない。いずれかの証明書や OS CA が
更新されたら、専用 bundle を安全に更新して service を再起動する。
自己署名証明書だけを指定すると Entra 接続が失敗する可能性がある。

DNS / TLS では社内 CA を含む OS CA bundle を使う例が
[TLS 版の手順](../../work/lore-tls/server-216-worked2.md#サービスと信頼設定) にある。
社内 CA と公開 CA の両方が含まれることを確認する。
選択した bundle を `lore-auth.service` の `[Service]` に設定する。
次は社内 IP の例。DNS / TLS では OS bundle の path に置き換える。

```ini
Environment=SSL_CERT_FILE=/opt/lore/certs/lore-auth-trust-bundle.pem
```

各 `test` の成功を確認してから、新規 DB と signing key を作る。
DNS / TLS では bundle の `test` の path も OS bundle に変更する。

```bash
sudo -u lore test -r /etc/lore/secrets/entra-client-secret
sudo -u lore test -r /opt/lore/certs/lore-server.key
sudo -u lore test -r /opt/lore/certs/lore-auth-trust-bundle.pem
sudo -u lore test -w /datadrive/lore/auth
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml init-db
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  key generate --kid lore-entra-01

sudo systemctl daemon-reload
sudo systemctl enable --now lore-auth nginx
```

216 の記録では `key generate --kid lore-216-01` を使用している。実行前に対象 binary の
`--help` を確認し、対応する command と YAML の `active_kid` を一致させる。

次は [bridge の受入確認](009-acceptance.md)。
