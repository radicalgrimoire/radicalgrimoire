# HelixCore AuthenticationService

構築手順簡易まとめ

# パッケージをインストールする

## リポジトリ追加  

* HelixCore 関連

[package-based installation](03_HelixCore_Document01)

* nodejs
```
yum install -y curl git gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
```

## インストール

* nodejsをインストール
```
yum -q -y install nodejs
npm install -g pm2
```

* helix-auth-svcをインストール
```
yum -y install helix-auth-svc
```

# 構築

## ペアのSSLの証明書の手配（今回は自己証明書で作成する）

* opensslコマンドを使って、自己証明書を作る

どこかで作成。ペアのSSL証明書が必要になる

```
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout ca.key -out ca.crt -subj "/CN=FakeAuthority"
openssl req -nodes -days 3650 -newkey rsa:4096 -keyout client.key -out client.csr -subj "/CN=LoginExtension"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -out client.crt -set_serial 01 -days 3650
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout server.key -out server.crt -subj "/CN=AuthService"
```

`HelixCore AuthenticationService`では  
`ca.crt`、`server.crt`、`server.key`を使う

`HelixCore AuthenticationExtension`では  
`ca.crt`、`client.crt`、`client.key`を使う

## 細かい設定内容

参考リンク

* [p4miscさんのドキュメント](https://github.com/p4misc/p4memo/blob/master/helix-authentication-service.md)
* [ExampleIdentityProviderconfigurations](https://www.perforce.com/manuals/helix-auth-svc/Content/HAS/example-configs.html)
* [Configuring Helix Authentication Service](https://www.perforce.com/manuals/helix-auth-svc/Content/HAS/configuring-has.html#Configuring_Helix_Authentication_Service)

## 起動する

公式ドキュメントでは、`下記スクリプトを実行しろ`と言ってる

```
/opt/perforce/helix-auth-svc/bin/configure-auth-service.sh 
```

だが、正直スクリプト実行結果で設定できる内容が微妙なので  
`ecosystem.config.js` を自分で編集して実行した方がマシ。

* 設定読み込み、HAS再起動

```
pm2 startOrReload ecosystem.config.js
```
