# Lore セットアップ

Lore Server、`lore-auth-bridge` と Windows client の構築資料。
[216 の社内 IP 環境](../work/lore-plaintext/) の実機記録を基準とし、
[TLS 環境の検討資料](../work/lore-tls/README.md) と分けて説明する。
実機で使った IdP は Microsoft Entra ID である。
以下は実機記録を一般化した手順であり、記載の path や service user を含め、
この手順全体を別環境で通し検証していない。

> [!WARNING]
> 構築例は新規環境向けである。既存の DB、store、鍵、certificate や設定を
> 初期化・上書きしない。

## 構成の選択

* 社内 IP / plaintext
  * Lore remote: `lore://<IP>:41337`
  * Lore gRPC: 平文。認証 token を含む通信は暗号化されない。
  * 認証経路: nginx の HTTPS と bridge gRPC の TLS を使用。
  * 状態: 216 の実機設定に基づく。

* DNS / TLS
  * Lore remote: `lores://<DNS_NAME>:41337`
  * Lore gRPC: TLS。証明書と名前の検証が必要。
  * 認証経路: nginx の HTTPS と bridge gRPC の TLS を使用。
  * 状態: サンプルは未完成・未検証。

plaintext は信頼できる社内 network に限り、network / firewall で接続先を制限する。
`0.0.0.0` 自体は社内限定を意味しない。DNS / TLS では DNS、証明書、
CA 信頼、client および bridge の `lores://` 対応を確認する。
クロニクラーは記録時点で `lores://` 未対応、bridge の既定 remote URL を省略した場合の
明示 URL によるログインも未検証である。選択した revision で解消を確認するまで本番適用しない。

## 同一 host での構築順序

管理者が 1〜3 を行い、利用者が 4 を行う。各段階の確認後に次へ進む。

1. **認証基盤** — [lore-auth-bridge と nginx](lore-auth-bridge/README.md) を構築し、
   [bridge 単体の受入確認](lore-auth-bridge/009-acceptance.md)を行う。
2. **Lore Server** — [Lore Server](lore-server/README.md) を構築し、
   [server 単体の受入確認](lore-server/005-acceptance.md)を行う。
3. **管理者** — [管理者ユーザーを作成](lore-auth-bridge/010-admin-user-setup.md)する。
   一般ユーザーの登録と repository 権限は [lore-authctl の利用者・権限管理](../guides/002-authctl.md)を参照する。
   repository は権限付与の前に作成・登録する。
4. **client と全体確認** — [Windows CLI](windows-cli-setup.md) を配置し、
   [証明書の信頼を設定](../operations/001-tls-troubleshooting.md#3-windows-client--runner-から確認する)する。
   [CLI の基本操作](../guides/001-cli-usage.md)で login、repository 一覧と clone を確認する。
   必要に応じて writer 操作と CI の login も別途検証する。

各手順の共通例は社内 IP / plaintext を基準とする。DNS / TLS の場合は各手順の
TLS 向け変更も一組として適用する。既存環境の方式切り替えには利用停止時間と
切り戻しを別途計画する。

## 資料の役割

- [lore-auth-bridge/](lore-auth-bridge/README.md) — Entra ID を使う認証基盤の構築と利用者登録。
- [lore-server/](lore-server/README.md) — server の構築と単体受入確認。
- [Windows CLI](windows-cli-setup.md) — 利用者の CLI インストール。

## 導入後

DB、JWT signing key、Lore store、設定を同時点の recovery set として backup し、
復元試験を行う。Entra client secret と certificate の期限を管理し、certificate は
client と runner に先に配布してから切り替える。
構築後の操作は[利用・管理ガイド](../guides/README.md)、
backup、更新、障害対応は[運用ガイド](../operations/README.md)、
実機での作業は[作業記録](../work/)を参照する。
