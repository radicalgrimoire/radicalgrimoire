# Auth Bridge 運用資料

`lore-auth-bridge` の概要、構成図、用語は [README](README.md) を参照してください。
このページは、実運用と認証基盤の資料への入口です。

## 実運用

- [アカウントとrepository権限の管理](setup/account-management.md) - Entra ID利用者の登録、identity binding、repository grant、確認。
- [Authctl](setup/authctl.md) - user、group、repository、grant、signing keyを操作するCLIのリファレンス。
- [Operations](setup/operations.md) - port、データ配置、backup、log、recovery、device flow。
- [管理 Web UI](setup/admin-ui.md) - `/admin` の有効化、権限、監査ログ。
- [Lore Server設定](setup/loreserver.md) - bridgeと `loreserver` の連携設定。
- [Lore Server と Entra認証付きbridgeの構築記録](../../work/server-215.md) - 実機導入の作業記録。
- [172.20.12.193のアカウント管理記録](../../work/server-193-account.md) - 既存環境の作業記録。

## 認証基盤

- [Configuration](setup/configuration.md) - bridgeのHTTP/gRPC、DB、JWT、Entra ID、security設定。
- [認証・認可の運用仕様](setup/authentication-authorization.md) - token、identity、grant、認可判定の契約。
- [TLS](setup/tls.md) - HTTP/gRPCの証明書とクライアント信頼。
- [Signing Keys](setup/signing-keys.md) - JWT signing keyの生成とrotation。
- [Deployment](setup/deployment.md) - reverse proxy、Tailscale、on-prem、cloudの配置方針。
- [Tailscale](setup/tailscale.md) - Tailscale越しに公開する場合の設定。
- [Entra ID連携の変更根拠と検証記録](setup/entra-id-integration-evidence.md)
- [Entra ID対応: bridge更新履歴と根拠](setup/entra-id-bridge-update-history.md)

## 開発・動作確認

- [Hands-on Quickstart](setup/hands-on-quickstart.md) - IdPを使わない単体完結の確認手順。
- [Lore JWT claim contractの検証](developing/claim-contract-verification.md) - Lore binary、bridge、またはIdP構成を変更した場合のJWT互換性確認。
