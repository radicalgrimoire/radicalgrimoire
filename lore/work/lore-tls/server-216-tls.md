# 216 向け Lore gRPC TLS 版

この文書は `lores://` を使う構成の検討用手順。
通常の平文版は ../lore-plaintext/server-216-worked1.md から
../lore-plaintext/server-216-worked4.md を使う。
TLS 版は未完成・未検証であり、この文書だけで実機に適用しない。
既存の 216 の設定や証明書をこの文書によって変更していない。

## TLS 版の構築手順

TLS 版の手順は同じフォルダの server-216-worked1.md から
server-216-worked4.md を使う。いずれも未検証。

## 共通部分と TLS の違い

ビルド、bridge、Nginx、アカウント作成などは平文版と同じ流れで進める。
TLS 版では平文版の Lore gRPC と bridge 接続先をそのまま使わず、
下記の設定を一組として準備する。証明書と設定の切り替えは通信に影響するため、
既存環境に適用する場合は切り戻し方法と作業時間を決める。

設定ファイルの例と前提の詳細は、同じフォルダの README.md を参照。
サンプルは社内 CA 発行証明書を使う例で、現在の 216 の自己署名証明書を
そのまま使う手順ではない。

## TLS 版で変更する箇所

1. 社内 CA 発行のサーバー証明書と秘密鍵を用意する。SAN にクライアントの接続先
   `172.20.11.216`、bridge が使う `127.0.0.1`、Nginx が検証する `localhost`
   を含める。発行・配布・更新は社内の CA 運用に従い、既存の証明書を上書きしない。
2. Lore Server の設定で、既存の `[server.grpc]` に加えて
   `[server.grpc.certificate]` を設定する。ファイルパスの例は
   gspcd581.toml を参照する。既存の TOML テーブルは重複させない。
3. bridge の `lore.repository_create_url` を `https://127.0.0.1:41337` にする。
   他の bridge 設定や証明書パスも確認する。例は
   lore-auth.yaml を参照する。
4. Nginx の証明書と bridge gRPC の検証先 CA を設定する。例は
   nginx.conf を参照する。認証用 Nginx の HTTPS と、
   Lore Server gRPC の TLS は別の接続経路。
5. Lore Server と bridge が必要な社内 CA と公開 CA の両方を信頼できるようにする。
   `SSL_CERT_FILE` を社内 CA だけにすると、bridge から Entra への接続に影響し得る。
   systemd の例は loreserver-trust.conf と
   lore-auth-trust.conf を参照し、既存の設定と重複させない。
   CA の配布と更新後の反映は社内の運用に従う。
6. クライアント側にも証明書の信頼を設定し、`lores://172.20.11.216:41337`
   を使用する。クライアントが使う証明書ストアを確認する。

`0.0.0.0` は全インターフェースで待ち受ける設定で、社内に限定する設定ではない。
公開範囲はネットワークとファイアウォールで制御する。

## 未解決事項

- クロニクラーは現状 `lores://` を受け付けない。URL の受け入れと証明書の信頼に対応が必要。
- 構築済み bridge は `default_remote_url` に `lores://` を受け付けない。
  設定を省略して明示 URL で利用する方法は未検証。必要なら bridge の対応も検討する。
- 証明書、各プロセスの信頼設定、ログイン、リポジトリ作成とクライアント操作を
  一連で検証していない。詳細な確認項目は README.md を参照。
