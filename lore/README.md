# Lore 社内検証・導入成果

このフォルダは、[Lore](https://github.com/EpicGames/lore) を社内で検証・利用するために行った実装、運用検証、設計判断をまとめる入口です。

Lore は Epic Games による、巨大なバイナリアセットを含むプロジェクトにも対応する次世代のオープンソースバージョン管理システムです。本取り組みでは、Lore 本体を動かすだけでなく、社内の ID 基盤でログインし、repository ごとの権限を管理し、実際に CLI から利用できる状態までを対象にしました

## 成果の要約

### Microsoft Entra ID と Lore の認証・認可を接続

Lore の CLI と server には認証を利用する仕組みがありますが、社内 IdP と接続して token を発行し、ユーザー・グループ・repository ごとの権限を管理するサービスは別途必要です。

そこで、Lore の UCS Auth / ReBAC protocol を実装する `lore-auth-bridge` を整備しました。

```text
Browser
  -> Microsoft Entra ID でログイン
  -> lore-auth-bridge が authn token を発行
  -> Lore CLI が repository 単位の authz token へ交換
  -> loreserver が JWT と ReBAC 権限を検証
  -> clone / push / repository 操作
```

Entra ID の email claim が未検証で返る実環境の課題には、email を本人確認に使わず、`<tenant-id>:<object-id>` で表される安定した identity を管理者が事前に bind する方式で対応しました。

- `lore-authctl user bind-identity` による管理操作
- identity binding と audit log の transaction による同時確定
- 同一 identity の別ユーザーへの紐付け拒否
- 冪等な onboarding script
- repository ごとの `reader` / `writer` / `admin` 権限

詳細は [auth-bridge](docs/auth-bridge/README.md) を参照してください。

### 社内 CA を利用する TLS gRPC 接続を実現

Lore CLI から認証 bridge へ接続する UCS Auth gRPC client に、OS の信頼済みルート証明書ストアを利用する TLS 設定を追加しました。

これは証明書検証を無効化する変更ではありません。社内 CA をクライアント端末の信頼ストアへ配布し、その CA が署名した bridge 証明書を通常どおり検証できるようにするものです。

この変更により、Entra login 後の repository-scoped token exchange を TLS 保護した gRPC で完結できます。

### 実機での end-to-end 検証

以下の経路を実機で確認しました。

1. Microsoft Entra ID で browser login
2. bridge による identity 解決と JWT 発行
3. Lore CLI から bridge への TLS gRPC 接続
4. repository 単位の authorization token exchange
5. ReBAC の writer 権限による repository 操作
6. Lore CLI による repository 作成
7. identity binding と onboarding script の冪等な再実行
8. SQLite への audit record 保存

bridge 側では、次の自動検証も成功しています。

```bash
cargo check -p lore-authctl
cargo test -p lore-auth-adapters --test sqlite
```

SQLite integration test は 24 件成功しています。

### 社内テスト運用の導線

Lore server を社内で継続的に試すため、データ保存先、設定、実行ユーザー、systemd service を固定する host-native の永続運用スクリプトを用意しました。

Docker / Compose の試用導線もありますが、これはローカル実験向けの補助選択肢です。状態を持つ VCS server の社内テスト運用を Docker に統一するかは、まだ決めていません。

## 時系列

| 時期 | 内容 | 到達点 |
| --- | --- | --- |
| 2026-08 | Entra ID の未検証 email claim を実機で確認 | 既存 invitation flow だけでは onboarding できないことを特定 |
| 2026-08 | Entra identity binding を実装 | Object ID を用いた安全な identity 登録と repository grant を実現 |
| 2026-08 | Lore の UCS Auth TLS gRPC 接続を修正 | 社内 CA を利用する bridge との token exchange を実現 |
| 2026-08 | ローカル試用と host-native 永続運用の導線を追加 | 実験・社内テスト運用の選択肢を整備 |
| 2026-09 | upstream tag の取り込みと社内更新手順を整備 | フォークを継続更新する運用を文書化 |
| 2026-10 | bridge を hardening し、サービスアカウント認証を追加 | 人間の利用者と自動処理の両方を認証対象に拡張 |

## 現在地と次の課題

### できていること

- Entra ID を使った Lore CLI login
- TLS で保護された token exchange
- ReBAC による repository 単位の認可
- audit を伴う identity onboarding
- 実機での repository 作成・操作
- host-native の永続運用導線
- サービスアカウント認証

### 今後の課題

- identity binding の専用自動テストを追加する
  - subject conflict
  - disabled user
  - audit 書き込み失敗時の rollback
- 監視、バックアップ、復旧を含む運用設計を固める
- テスト利用チームを通じて onboarding と権限管理の UX を検証する
- Docker を補助導線として維持するか、host-native 運用に寄せるかを実運用の知見で判断する

## ドキュメント案内

- [認証 bridge の概要](docs/auth-bridge/README.md)
- [Entra ID 対応の変更履歴と根拠](docs/auth-bridge/setup/entra-id-bridge-update-history.md)
- [Entra ID 連携の変更根拠と検証記録](docs/auth-bridge/setup/entra-id-integration-evidence.md)
- [手順・検証メモ](guides/)
- [作業記録](work/)
