# 216 の loreserver サービス

2026-11-09 に確認した設定。サーバー設定は [gspcd581.toml.md](./gspcd581.toml.md) を参照する。

`/etc/systemd/system/loreserver.service`:

```ini
[Unit]
Description=LORE Server
After=network.target
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive

[Service]
Type=simple
User=mgs
Group=mgs
UMask=0077
ExecStart=/datadrive/lore/bin/loreserver --config /datadrive/lore/config --env gspcd581
Restart=on-failure
RestartSec=5
Environment=SSL_CERT_FILE=/datadrive/lore/certs/lore-server.crt

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/loreserver.service.d/override.conf`:

```ini
[Unit]
Wants=lore-auth.service nginx.service
After=lore-auth.service nginx.service
```

`Wants` と `After` は起動順序などを指定するが、依存先の正常応答を保証しない。
