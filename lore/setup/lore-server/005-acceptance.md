# Lore Server の受入確認

[systemd による起動](004-systemd.md) の後に、service と listener を確認する。
一般化した手順は別環境で通し検証していない。

```bash
systemctl is-enabled lore-auth nginx loreserver
systemctl is-active lore-auth nginx loreserver
sudo ss -lntup | grep -E ':(41337|41339)\b'
sudo journalctl -u loreserver -n 100 --no-pager
```

3 service が `enabled` / `active`、Lore の TCP・UDP listener が想定どおりであることを確認する。
HTTP health の成功だけでは gRPC の動作や client の trust は確認できない。

次は [Windows client の初回接続](006-windows-client.md)。
