# 216 向け lores:// 構成サンプル

2026-11-10 の検討用サンプル。216 の実機には適用していない。
現状の実機設定は ../lore-plaintext の作業記録を参照する。このサンプルは完成済みの
構築手順ではなく、以下の未解決事項を含む。

## TLS 版の構築手順

平文版と同じ順序の手順を用意している。いずれも未検証。

1. [Lore CLI と Lore Server](./server-216-worked1.md)
2. [lore-auth-bridge](./server-216-worked2.md)
3. [Nginx](./server-216-worked3.md)
4. [認証設定と社内向け待受](./server-216-worked4.md)

## ファイル

| サンプル | 対象 |
|---|---|
| [gspcd581.toml](./gspcd581.toml) | Lore Server の設定 |
| [lore-auth.yaml](./lore-auth.yaml) | lore-auth-bridge の設定 |
| [nginx.conf](./nginx.conf) | Nginx の site 設定 |
| [loreserver-trust.conf](./loreserver-trust.conf) | loreserver の systemd drop-in |
| [lore-auth-trust.conf](./lore-auth-trust.conf) | lore-auth の systemd drop-in |

systemd の例は `SSL_CERT_FILE` の設定部分のみ。既存の unit と drop-in を確認し、
同じ環境変数の設定が重複しないようにする。既存のサービス定義や依存関係は別途必要。

## 証明書と接続

この例では、社内 CA が発行した証明書を以下のように配置する前提とする。
証明書や鍵はこのサンプルに含めない。既存の鍵や証明書を上書きしない。

| パス | 用途 |
|---|---|
| `/datadrive/lore/certs/lore-server.crt` | サーバー証明書。必要に応じて中間証明書を含む chain |
| `/datadrive/lore/certs/lore-server.key` | サーバー秘密鍵。権限を制限する |
| `/datadrive/lore/certs/lore-ca.crt` | Nginx が bridge の証明書検証に使う信頼 CA |

証明書の SAN には、社内クライアントが使用する `IP:172.20.11.216`、
bridge から Lore gRPC に接続する `IP:127.0.0.1`、
Nginx が bridge gRPC の検証に使う `DNS:localhost` を含める。DNS 名を使うなら、
その名前も含め、URL と Entra の callback 登録を揃える。

Ubuntu のシステム CA bundle に社内 CA を登録し、Lore Server と bridge が
社内 CA および Entra に必要な公開 CA を信頼できるようにする。
Windows クライアントにも適切な社内 CA の信頼設定が必要。管理者のポリシーに従い、
配布するのは CA 証明書であって CA 秘密鍵ではない。
クライアントの実装がどの証明書ストアを使うかも確認する。

216 の既存の自己署名証明書を使う場合は、CA 発行証明書を前提とする上の例と
信頼設定が異なる。証明書の発行元・SAN と各プロセスの trust anchor を確認し、
自己署名証明書を明示的に信頼する方法を別途検証する。

| 経路 | 接続先 | 信頼 |
|---|---|---|
| 社内端末 → Lore | `lores://172.20.11.216:41337` | 端末が Lore の証明書を検証 |
| 社内端末 → Nginx | HTTPS 8080 / gRPC TLS 8081 | 端末が Nginx の証明書を検証 |
| Nginx → bridge gRPC | `grpcs://127.0.0.1:18081` | Nginx が CA と `localhost` を検証 |
| Lore Server → 認証 gRPC | `https://172.20.11.216:8081` | Lore Server が OS CA bundle を使用 |
| bridge → Lore gRPC | `https://127.0.0.1:41337` | bridge が OS CA bundle を使用 |
| bridge → Entra | HTTPS | bridge が公開 CA を使用 |

証明書の更新後は、chain・CA・OS bundle とサービスの再読み込みを含めて検証する。
`SSL_CERT_FILE` を専用 CA だけにすると、公開 CA を使う Entra 接続に影響し得る。

## クロニクラーと bridge の未解決事項

- クロニクラーは現状 `lores://` を受け付けないため、この設定例だけでは利用できない。
  ツールの URL 入力、保存、Lore への受け渡し、証明書信頼を調査・対応し、
  サインインと repository 操作まで確認する。ツールのソースはこの検討では未確認。
- 構築済み bridge の commit `43eb86062da7f45cc4f7e75668af91c18a45380d` は、
  `lore.default_remote_url` に `lores://` を受け付けない。サンプルでは省略している。
  省略すると既定 URL の補完を利用できないため、明示的な `lores://` 指定で
  CLI・クロニクラーのログインが完了するか検証が必要。必要なら bridge の対応を検討する。
- `email_binding: disabled` は招待を使わない方針の例。既存の pending 招待は
  設定を変えても削除されない。実機に反映する前に影響を確認する。

## 適用前後の確認項目

- `0.0.0.0` の 41337/TCP・UDP は全 IPv4 インターフェースで待ち受ける。
  公開先はネットワーク・ファイアウォールで決める。8081 は社内 IP で待ち受け、
  ReBAC は必要な Lore Server のみ許可する。
- SAN、信頼チェーン、有効期限、秘密鍵の権限と更新手順を確認する。
- `nginx -t` を含む設定検証と、各サービスの状態・health を確認する。
- 証明書検証付きで Lore gRPC、認証 gRPC、Entra 接続を確認する。
- クライアントで `lore auth login lores://172.20.11.216:41337` を試し、
  クロニクラーでもサインインと repository 操作を確認する。
- 管理画面からの repository 作成と ReBAC 同期を確認する。
  途中で失敗した場合は既存の Lore データ・認可レコードを調査してから再試行する。

これらは実機での検証待ち。サンプルの保存だけでは変更も検証も行われない。
