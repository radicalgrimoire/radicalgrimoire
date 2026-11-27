# 216 の lore-auth サービス

2026-11-09 に確認した設定。bridge の YAML は
[lore-auth-config.md](./lore-auth-config.md) を参照する。

`/etc/systemd/system/lore-auth.service`:

```ini
[Unit]
Description=LORE Auth Bridge
After=network-online.target
Wants=network-online.target
RequiresMountsFor=/datadrive
ConditionPathIsMountPoint=/datadrive

[Service]
Type=simple
User=mgs
Group=mgs
UMask=0077
ExecStart=/datadrive/lore/bin/lore-auth-server --config /datadrive/lore/config/lore-auth.yaml
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/datadrive/lore/auth

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/lore-auth.service.d/lore-trust.conf`:

```ini
[Service]
Environment=SSL_CERT_FILE=/datadrive/lore/certs/lore-auth-trust-bundle.pem
```

このバンドルには、作成時点の Ubuntu の CA bundle と Lore の自己署名証明書を
含めている。どちらかの証明書を更新した場合は、バンドルの再作成と
`lore-auth` の再起動が必要。OS の CA 更新だけではバンドルは自動更新されない。