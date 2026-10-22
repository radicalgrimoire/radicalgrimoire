# 172.20.12.215: 未完了作業

## TLS certificate の計画更新

### 期限

- 計画開始期限: **2027-09-01**
- 現行 certificate の失効日時: **2027-10-19 03:13:23 UTC**

### 現在の状態

`/opt/lore/certs/lore-server.crt` は `172.20.12.215` 用の自己署名 TLS server
certificate である。

| 項目 | 値 |
| --- | --- |
| Subject / issuer | `CN=172.20.12.215` |
| SAN | `IP:172.20.12.215`, `DNS:localhost`, `IP:127.0.0.1` |
| SHA-256 fingerprint | `96:4E:72:9A:CB:34:AF:44:89:8D:C7:83:B9:EA:CB:2B:F9:2E:8C:9F:81:69:05:95:55:70:99:97:18:E0:6B:6A` |

現時点では更新しない。既存の Lore client はこの certificate を Windows の Trusted Root
store に登録しているため、certificate / private key を更新すると、新 certificate を
trust していない利用者は Lore login、clone、pull、push ができなくなる。

### 更新時の手順

1. 新 certificate と private key を作成する。SAN に `172.20.12.215`、`localhost`、
   `127.0.0.1` を含める。
2. 新しい public certificate を、既存の利用者と CI runner の Local Machine Trusted Root
   store へ先に追加する。
3. 全利用者・runner への配布完了を確認する。
4. `/opt/lore/certs/lore-server.crt` と `/opt/lore/certs/lore-server.key` を新しい
   key pair へ切り替える。
5. `lore-auth`、nginx、loreserver を restart し、Entra login、Lore clone、CI
   Service Account login を確認する。
6. 旧 certificate は、新 certificate での全接続を確認してから trust store から削除する。

詳細は [bridge TLS certificate の運用](./server-193-bridge-tls.md) を 215 の endpoint と
certificate path に読み替えて実施する。
