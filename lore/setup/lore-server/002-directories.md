# Lore Server の directory 作成

[前提条件](README.md)と [build・配置](001-build.md)を確認する。
既存 directory がある場合、内容と影響を確認してから permission を変更する。

```bash
sudo install -d -o root -g lore -m 0750 /opt/lore/config/lore-server
sudo install -d -o lore -g lore -m 0750 /datadrive/lore/store
```

次は [Lore Server 設定](003-server-config.md)。
