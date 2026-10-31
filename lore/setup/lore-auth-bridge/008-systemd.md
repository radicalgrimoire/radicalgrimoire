# systemd と初期化

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

`/etc/systemd/system/lore-auth.service`:

```ini
[Unit]
Description=Lore authentication bridge
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/datadrive

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
確認の代わりにはならない。各 `test` の成功を確認してから、新規 DB と signing key を作る。

```bash
sudo -u lore test -r /etc/lore/secrets/entra-client-secret
sudo -u lore test -r /opt/lore/certs/lore-server.key
sudo -u lore test -w /datadrive/lore/auth
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml init-db
sudo -u lore /opt/lore/bin/lore-authctl --config /opt/lore/config/lore-auth.yaml \
  signing-key generate --kid lore-entra-01

sudo systemctl daemon-reload
sudo systemctl enable --now lore-auth nginx
```

次は [bridge の受入確認](009-acceptance.md)。
