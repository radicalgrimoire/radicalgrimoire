# Lore Server の systemd と起動

先に [前提条件](README.md) と [Lore Server 設定](003-server-config.md) を確認する。

`/etc/systemd/system/loreserver.service`:

```ini
[Unit]
Description=Lore server
After=network-online.target lore-auth.service
Wants=network-online.target
RequiresMountsFor=/datadrive

[Service]
Type=simple
User=lore
Group=lore
WorkingDirectory=/opt/lore
Environment=SSL_CERT_FILE=/opt/lore/certs/lore-server.crt
ExecStart=/opt/lore/bin/loreserver --config /opt/lore/config/lore-server --env production
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/datadrive/lore/store

[Install]
WantedBy=multi-user.target
```

`RequiresMountsFor` は mount dependency を設定するが、意図した device が mount されているかの
確認の代わりにはならない。service user が certificate を読め、store に書けることを確認する。
各 `test` の成功を確認してから service を起動する。

```bash
sudo -u lore test -r /opt/lore/certs/lore-server.key
sudo -u lore test -w /datadrive/lore/store
sudo systemctl daemon-reload
sudo systemctl enable --now loreserver
```

次は [server の受入確認](005-acceptance.md)。
