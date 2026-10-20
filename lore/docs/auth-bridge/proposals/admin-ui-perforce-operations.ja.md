# 管理 Web UI を Perforce 相当の運用機能へ拡張するための要件整理

**Status:** Planned

## 背景

`lore-auth-bridge` の `/admin` は、Lore deployment の user、group、repository、
grant、実効アクセスを管理する Web UI である。

現状の運用では、Entra identity binding や repository grant の登録に
`lore-authctl` と `onboard-entra-user.sh` を使う。日常的な管理操作を Web UI で
安全かつ追跡可能に実施できるようにし、Perforce で一般的な管理者操作に近い運用体験を
目指す。

この文書は機能実装の仕様ではない。管理 Web UI の要件、Lore Server と bridge の責務
境界、実装ロードマップを合意するための親タスクである。

## 現在の機能

`/admin` は、設定した管理者だけが利用できる。現在、次を提供する。

- user、group、repository、grant、user access の閲覧と検索
- user の追加・無効化、invitation の作成
- manual repository の追加・無効化
- group、nested group、grant の管理
- user、repository、action を指定する access simulator
- 管理操作の audit log

管理 UI の有効化には `lore-auth.yaml` の `admin.admin_emails` を設定し、管理者は
OIDC login 後に `/admin` を開く。

## 目標

Perforce の運用機能を参考にしつつ、Lore の設計と運用上の責務に合う Web UI を作る。
Perforce の画面や API をそのまま再現することは目標にしない。

優先するのは、管理者が「誰が、どの repository に、なぜアクセスできるのか」を
ブラウザで把握し、安全に変更できることである。

## 要件整理

### 1. Perforce との対応を整理する

次の対応表を作成し、各項目を採用、変更して採用、対象外に分類する。

| Perforce の運用概念 | Lore / bridge の対応候補 | 検討事項 |
| --- | --- | --- |
| User | bridge user と external identity | Entra lifecycle、無効化、identity binding |
| Group | group と nested group | membership と継承経路の可視化 |
| Depot / stream のアクセス | repository grant | resource 単位、role、継承の表現 |
| Protect table | grant と role | reader / writer / admin の操作範囲 |
| Admin audit | `admin_audit` | 検索、保持期間、変更前後の表示 |
| Server / repository lifecycle | Lore Server と ReBAC sync | bridge UI が操作してよい境界 |

### 2. 管理フローを定義する

次のフローについて、画面遷移、入力項目、確認表示、失敗時の扱いを定義する。

- user の検索、追加、無効化、有効化
- Entra identity binding の表示、追加、競合時の診断
- repository 一覧と repository ごとのアクセス管理
- user を起点とした実効アクセス可能 repository の一覧
- group と nested group の管理
- grant の追加、変更、削除
- 変更の影響範囲と付与根拠の可視化
- audit log の検索と詳細表示

user access は、direct grant だけでなく group および nested group 経由の実効権限と、
どの grant によって許可されたかを表示する。

### 3. CLI と Web UI の責務を分ける

次を明確にする。

- 日常の user / group / grant 管理で Web UI に載せる操作
- bootstrap、復旧、automation、低レベル診断として `lore-authctl` に残す操作
- `onboard-entra-user.sh` のような複数操作をまとめた運用手順と UI の関係

Web UI は CLI の単純な置き換えではなく、入力検証、影響範囲の表示、監査を提供する。

### 4. セキュリティと運用要件を定義する

- 管理者の認可モデルと最後の管理者を失う操作への保護
- 非管理者や未認証者へ管理機能の存在・データを露出しないこと
- reverse proxy、送信元制限、rate limit を含む `/admin` の公開境界
- すべての mutation の監査記録
- identity、grant、group 変更時の競合・誤操作・ロールバックの扱い
- token、client secret、private key を UI や監査ログに表示しないこと

### 5. Lore Server との境界を確定する

repository の保存、create、delete は Lore Server の責務である。bridge は identity と
authorization を管理し、Lore Server の ReBAC synchronization で repository lifecycle
を追従する。

管理 UI から repository lifecycle に関わる操作を提供する場合は、Lore Server API を
介すること、ReBAC sync の整合性、失敗時の復旧を設計する。bridge DB だけを直接更新して
Lore Server の状態を代替してはならない。

## 完了条件

- Perforce 相当機能との対応表と対象外項目が文書化されている。
- 優先度付きの Web UI 要件、画面フロー、権限モデルが合意されている。
- セキュリティ、監査、運用の受け入れ条件が定義されている。
- 実装可能な小さな follow-up task に分割されている。

## 関連資料

- [管理 Web UI](../setup/admin-ui.ja.md)
- [Authctl](../setup/authctl.ja.md)
- [Microsoft Entra ID](../setup/entra-id.ja.md)
- [172.20.12.193: Lore と lore-auth-bridge の構築記録](../setup/on-prem-entra-lore-server.ja.md)
