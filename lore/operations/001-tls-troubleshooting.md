# TLS 証明書の確認とトラブルシューティング

旧 TLS 資料と [実機の証明書運用記録](../work/server-193-bridge-tls.md) を
基に整理した。コマンド例は [bridge 構築手順](../setup/001-auth-bridge-setup.md) の同一 host 構成を前提とする。
使用する binary の revision と certificate の配布方式により挙動は異なるため、実環境で確認する。

## 1. 接続先と証明書を確認する

管理者が bridge host で実行する。`<SERVER_HOST>` は client の接続先 DNS 名または IP、
`<TRUST_CERT_FILE>` は信頼する CA certificate または自己署名 server certificate に置き換える。

```bash
openssl x509 -in /opt/lore/certs/lore-server.crt -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName
openssl verify -CAfile <TRUST_CERT_FILE> /opt/lore/certs/lore-server.crt
curl --fail --cacert <TRUST_CERT_FILE> https://<SERVER_HOST>:8080/healthz
curl --fail --cacert <TRUST_CERT_FILE> https://<SERVER_HOST>:8080/.well-known/jwks.json
```

`openssl verify` の `OK` は証明書 chain の確認であり、接続先 hostname/IP の確認や gRPC の
受入確認の代わりにはならない。`curl` は TLS 検証付きで health と JWKS が応答することを確認する。
SAN に client が使う DNS 名または IP が含まれ、有効期限内であることも確認する。
HTTP endpoint の成功だけでは gRPC が動くとは限らない。

## 2. `SSL_CERT_FILE` の信頼先を確認する

```bash
sudo systemctl show loreserver -p Environment
sudo systemctl status lore-auth nginx loreserver --no-pager
sudo journalctl -u lore-auth -u loreserver -n 100 --no-pager
```

ログに token や secret がないことを確認してから共有する。systemd の環境変数を変更した場合は
`daemon-reload` と対象 service の再起動が必要になる。

- **組織 CA / mkcert:** `SSL_CERT_FILE` には、server certificate を発行した信頼済み CA の
  certificate または CA bundle を指定する。CA が署名した leaf だけを信頼先として指定しない。
- **自己署名 server certificate:** 実機では、その公開 server certificate 自身を trust anchor と
  して使った。private key を client に配布しない。
- **OS trust store:** 実際に使われる trust source は Lore / TLS library の revision と
  `SSL_CERT_FILE` の有無に依存する。OS store と明示ファイルが併用されると決めつけず確認する。

旧資料では、login が成功しても repository 作成時に
`Failed to connect to rebac service` になる例を記録している。署名済み leaf を
`SSL_CERT_FILE` に指定していないか、Lore Server 側のログ・CA・gRPC 接続先を確認する。
これは原因の一例であり、同じエラーの原因が常に TLS とは限らない。
特に `lore auth login --token` は token のローカル保存だけの場合があり、bridge への gRPC
接続が成功したことを意味しない。

## 3. Windows client / runner から確認する

管理者が安全な経路で配布した certificate の SHA-256 fingerprint を照合し、必要な trust
store に追加する手順は [Windows CLI インストール手順](../setup/003-windows-cli-setup.md#4-certificate-を信頼しログインする)
を参照する。Windows service account で実行する runner では、必要に応じて Local Machine store
を管理者が更新する。

```powershell
Test-NetConnection <SERVER_HOST> -Port 8081
lore auth login lore://<SERVER_HOST>:41337
lore clone lore://<SERVER_HOST>:41337/<REPOSITORY> "C:\Path\To\NewClone"
```

`Test-NetConnection` は TCP 到達性だけを確認する。TLS、HTTP/2 gRPC、認証、認可は実際の login
と、権限のある repository の clone まで確認する。`--insecure` による確認で代用しない。

## 4. certificate を更新するとき

1. 利用者と CI runner を洗い出し、新 certificate の SAN、期限、SHA-256 fingerprint を確認する。
2. 必要な trust anchor を全 client / runner に先に配布し、fingerprint と登録を確認する。
3. 旧 key pair と設定の安全な backup、停止時間、rollback 手順を準備する。
4. 構成に応じて server の key pair を切り替え、bridge、nginx、Lore Server の必要な service を
   再起動または reload する。nginx は `nginx -t` の成功後に reload する。
5. 各 service と endpoint を確認し、Entra login、clone、必要な CI の Service Account login を
   実際に検証する。すべての利用者で切替を確認してから旧 trust を削除する。

実機ごとの path と手順は [193 の記録](../work/server-193-bridge-tls.md) および
[215 の更新計画](../work/server-215-todo.md) を参照する。後者は計画であり、実施済みの記録ではない。
