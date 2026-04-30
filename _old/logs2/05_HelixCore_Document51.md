# SSL対応用の鍵をAzure KeyVaultで管理する

HelixCoreをSAML接続対応する際に、SSL化が必要なのですが、
そのSSLで必要になる鍵の管理をKeyVaultで管理した記録

## キーコンテナーを作成する

* azure portal にログインする。キーコンテナーページから新規作成
* サブスクリプション、リソースグループ、リージョン、他いろいろと適切な入力
* アクセスポリシーで `Azure Virtual Machines`、`Azure Resource Manager`にチェックを入れておく。

上記２つをちゃんとしたら作成ボタン。

## ペアの鍵を作る

HelixCoreのSAML化対応ではペアの鍵が必要です  
また下記sampleコマンドを入力してsslの鍵を作ったとしても、AzureKeyVaultで管理できる物は`pfx形式のみ`であるため
作成後にpfx形式に変換する
```
# sample
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout ca.key -out ca.crt -subj "/CN=FakeAuthority"
openssl req -nodes -days 3650 -newkey rsa:4096 -keyout client.key -out client.csr -subj "/CN=LoginExtension"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -out client.crt -set_serial 01 -days 3650
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout server.key -out server.crt -subj "/CN=AuthService"
```

Helix Authentication Extension用のpfxファイルを作る
```
openssl pkcs12 -export -out client.pfx -inkey client.key -in client.crt -certfile ca.crt
```

Helix Authentication Service用のpfxファイルを作る
```
openssl pkcs12 -export -out server.pfx -inkey server.key -in server.crt -certfile ca.crt
```

azure key vaultに証明書を登録する

![key.vault.01.png](https://raw.githubusercontent.com/hexagrimoire/WorkNote/main/image/key.vault.01.png)

ここから、「作成／インポート」を選択  
作成した `client.pfx` と `server.pfx` を登録する

## 作成したペアの鍵を取得する

[https://gist.github.com/hexagrimoire/17897a32b50a9ea5f0622cf0cbd79a92](https://gist.github.com/hexagrimoire/17897a32b50a9ea5f0622cf0cbd79a92)

これを使う。


Helix Authentication Extension用のpfxファイルから、鍵を展開し、所定の場所に配置する

```
bash get-keyvault-certificate.sh <キーコンテナー名> client

pushd [helix-authentication-extension をcloneした場所]
\cp -f /etc/letsencrypt/live/client/cert.pem ./loginhook/client.crt
\cp -f /etc/letsencrypt/live/client/privkey.pem ./loginhook/client.key
\cp -f /etc/letsencrypt/live/client/chain.pem ./loginhook/ca.crt
```

Helix Authentication Service用のpfxから展開する

```
bash /opt/perforce/helix-auth-svc/get-keyvault-certificate.sh <キーコンテナー名> server

\cp -f /etc/letsencrypt/live/server/cert.pem /opt/perforce/helix-auth-svc/certs/server.crt
\cp -f /etc/letsencrypt/live/server/privkey.pem /opt/perforce/helix-auth-svc/certs/server.key
\cp -f /etc/letsencrypt/live/server/chain.pem /opt/perforce/helix-auth-svc/certs/ca.crt
```

