# Lore Server の受入確認

[systemd による起動](004-systemd.md) の後に、service と listener を確認する。
一般化した手順は別環境で通し検証していない。

## Server 単体の確認

```bash
systemctl is-enabled lore-auth nginx loreserver
systemctl is-active lore-auth nginx loreserver
sudo ss -lntup | grep -E ':(41337|41339)\b'
curl --noproxy '*' --fail http://127.0.0.1:41339/health_check
sudo journalctl -u loreserver -n 100 --no-pager
```

3 service が `enabled` / `active`、Lore の TCP・UDP listener が想定どおりであることを確認する。
HTTP health の成功だけでは gRPC の動作や client の trust は確認できない。

## 利用者と client を含む確認

1. [管理者ユーザーを作成](../lore-auth-bridge/010-admin-user-setup.md)し、
   [利用者登録と repository 権限](../../guides/002-authctl.md)を設定する。
2. [Windows CLI](../windows-cli-setup.md) をインストールし、
   [証明書の信頼を設定](../../operations/001-tls-troubleshooting.md#3-windows-client--runner-から確認する)する。
   [CLI の基本操作](../../guides/001-cli-usage.md)で login、一覧と clone を確認する。
3. repository 作成・認可を確認し、必要な場合は writer 操作と CI の login も別途検証する。

TLS 版は証明書の SAN、chain と各 process の trust も検証する。未検証の TLS 版では
client / bridge の対応確認を完了するまで本番扱いしない。障害時は
[TLS の確認と切り分け](../../operations/001-tls-troubleshooting.md)を参照する。
導入後は[バックアップと復旧](../../operations/002-backup-recovery.md)を確認する。
