# Lore ドキュメント

Lore の社内検証・導入における成果、構築・運用手順、作業記録の入口。
Microsoft Entra ID での login から repository ごとの権限管理、CLI 利用までを対象とする。

## 検証・導入の成果

### 認証・認可

Lore の UCS Auth / ReBAC protocol を実装する `lore-auth-bridge` を整備し、
Entra ID と Lore を接続した。Entra ID の email claim が未検証で返る環境では、
email を本人確認に使わず、管理者が `<tenant-id>:<object-id>` を user に事前に bind する。
identity binding と audit log は transaction で同時確定し、同じ identity を別 user に
紐付ける操作は拒否する。当時の onboarding script は後に削除されており、現在は
管理 UI または CLI で登録する。

repository ごとに `reader` / `writer` / `admin` の権限を管理でき、
サービスアカウント認証にも対応している。操作手順は
[lore-authctl の操作](guides/authctl.md) と
[CI Service Account の設定](operations/ci-service-account.md) を参照する。

bridge は登録済み identity に authn token を発行し、Lore CLI は repository 操作時に
`UrcAuthApi` で短命の repository scoped authz token を取得する。Lore Server は JWKS で
署名を検証し、`RebacApi` で repository の作成・削除を bridge に同期する。
login の成功だけでは repository 権限は付与されない。

### TLS gRPC

Lore CLI の UCS Auth gRPC client に、OS の信頼済みルート証明書ストアを利用する TLS 設定を
追加した。証明書検証を無効化せず、端末の信頼ストアに配布した社内 CA が署名する bridge
証明書を検証する。これにより、Entra login 後の repository-scoped token exchange を
TLS 保護した gRPC で完結できる。

証明書の信頼設定は環境や client revision に依存する。実機での自己署名証明書の運用例は
[証明書運用記録](work/server-193-bridge-tls.md) を参照する。

### end-to-end 検証

以下の経路を実機で確認した。

1. Microsoft Entra ID で browser login
2. bridge による identity 解決と JWT 発行
3. Lore CLI から bridge への TLS gRPC 接続
4. repository 単位の authorization token exchange
5. ReBAC の writer 権限による repository 操作
6. Lore CLI による repository 作成
7. identity binding と onboarding script の冪等な再実行
8. SQLite への audit record 保存

bridge 側では、次の自動検証も成功した。

```bash
cargo check -p lore-authctl
cargo test -p lore-auth-adapters --test sqlite
```

当時の SQLite integration test は 24 件成功した。これは記録当時の結果であり、現在の
revision で同じ件数や coverage を確認したことを意味しない。

### 社内テスト運用

データ保存先、設定、実行ユーザー、systemd service を固定する host-native の永続運用
スクリプトを用意した。Docker / Compose の試用導線もあるが、ローカル実験向けの補助選択肢
であり、状態を持つ VCS server の社内テスト運用を Docker に統一するかは未決定である。

## 時系列

| 時期 | 内容 | 到達点 |
| --- | --- | --- |
| 2026-08 | Entra ID の未検証 email claim を実機で確認 | 既存 invitation flow だけでは onboarding できないことを特定 |
| 2026-08 | Entra identity binding を実装 | Object ID を用いた安全な identity 登録と repository grant を実現 |
| 2026-08 | Lore の UCS Auth TLS gRPC 接続を修正 | 社内 CA を利用する bridge との token exchange を実現 |
| 2026-08 | ローカル試用と host-native 永続運用の導線を追加 | 実験・社内テスト運用の選択肢を整備 |
| 2026-09 | upstream tag の取り込みと社内更新手順を整備 | フォークを継続更新する運用を文書化 |
| 2026-10 | bridge を hardening し、サービスアカウント認証を追加 | 人間の利用者と自動処理の両方を認証対象に拡張 |

## 今後の課題

- identity binding の subject conflict、disabled user、audit 失敗時の rollback について、
  使用する revision の自動テストと実機の coverage を確認する
- 監視、バックアップ、復旧を含む運用設計を固める
- テスト利用チームを通じて onboarding と権限管理の UX を検証する
- Docker を補助導線として維持するか、host-native 運用に寄せるかを実運用の知見で判断する

## 構築

同一 host に bridge と Lore Server を構築し、Windows client を接続する場合は、
次の順に進める。

1. [lore-auth-bridge 構築手順](setup/auth-bridge-setup.md) — bridge、Entra ID、TLS、nginx の構築。
2. [Lore Server 構築手順](setup/server-setup.md) — Lore Server の構築と client からの接続確認。
3. [Windows CLI インストール手順](setup/windows-cli-setup.md) — client の配置、証明書、初回接続。

その他の構成:

- [Identity Provider と招待](setup/identity-providers.md) — Google、Entra ID、Keycloak と binding。
- [Tailscale 構成](setup/tailscale.md) — private mesh での endpoint と trust。
- [IdP を使わないローカル検証](setup/local-auth-quickstart.md) — 手動 token を使う検証の流れ。

## 管理・運用

- [TLS の確認と切り分け](operations/tls-troubleshooting.md) — certificate、trust、接続と更新。
- [管理 Web UI の設定と操作](admin-webtools/README.md) — 公開範囲の制限と管理操作。
- [バックアップと復旧](operations/backup-recovery.md) — offline backup と復元試験。
- [CI Service Account の設定](operations/ci-service-account.md) — runner の認証と権限。
- [Lore Server / bridge の更新](operations/upgrade.md) — 更新、受入、rollback。
- [token 発行と device flow](operations/token-flows.md) — 手動発行、Web token、device flow。
- [bridge の開発・互換性検証](operations/bridge-validation.md) — build、test、E2E、claim contract。

## 利用者向け

- [CLI の基本操作](guides/cli-usage.md) — login、clone、commit、push。
- [lore-authctl の操作](guides/authctl.md) — 管理者向けの user、group、repository 権限。

## 資料の扱い

上記の構築・管理・運用・利用者向け資料は
[実機導入記録](work/server-215.md) や旧資料を基に一般化した手順であり、
一般化後の手順自体は実機での通し検証を行っていない。`<...>` を実環境の値に置き換え、
使用する binary の version と設定 schema を確認する。

実機の導入・更新・運用記録は [作業記録](work/) に残している。実機記録と
対象環境の動作を優先する。
