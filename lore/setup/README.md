# Lore セットアップ

Lore Server、`lore-auth-bridge` と Windows client の構築資料。
一般化した手順は別環境で通し検証していない。使用する binary の revision と互換性、
各資料の前提条件を確認する。

> [!WARNING]
> 構築例は新規環境向けである。既存の DB、store、鍵、certificate や設定を
> 初期化・上書きしない。

## 同一 host での構築

1. [lore-auth-bridge 構築手順](lore-auth-bridge/README.md) に従い、
   bridge と nginx の[受入確認](lore-auth-bridge/009-acceptance.md)まで進める。
2. [Lore Server 構築手順](lore-server/README.md) に従い、
   server の[受入確認](lore-server/005-acceptance.md)まで進める。
3. bridge で[利用者登録と repository 権限の設定](lore-auth-bridge/010-user-onboarding.md)を行う。
4. [Windows CLI インストール](001-windows-cli-setup.md)に従い、client を接続する。

## その他の構成

- [Identity Provider と招待](lore-auth-bridge/012-identity-providers.md) — IdP と identity binding。
- [Tailscale 越しの bridge と Lore](002-tailscale.md) — private mesh の接続と信頼設定。
- [IdP を使わないローカル検証](003-local-auth-quickstart.md) — 本番とは別の検証環境で経路を確認する。

構築後の操作は[利用・管理ガイド](../guides/README.md)、
保守と障害対応は[運用ガイド](../operations/README.md)を参照する。
