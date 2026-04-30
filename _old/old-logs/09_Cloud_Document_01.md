# AzureADを活用してJenkinsにログインする

## 前提

jenkins公式のDockerイメージを使ってjenkinsを準備します。  
使うイメージタグは`jenkins:jenkins:lts`です  
※jenkinsを準備する所は省略

JenkinsからAzureADに接続するためのプラグインは  
`Azure AD` プラグインを使います。

## JenkinsのSSL化対応

* opensslをインストール

* 鍵の生成

```
openssl genrsa -out "$CERT_FOLDER/jenkins.key" 4096
openssl req -new -key "$CERT_FOLDER/jenkins.key" -out "$CERT_FOLDER/jenkins.csr" -subj "/C=US/ST=Example/L=Example/O=Game Studio Inc./CN=www.example.com"
openssl x509 -req -days 3560 -in "$CERT_FOLDER/jenkins.csr" -signkey "$CERT_FOLDER/jenkins.key" -out "$CERT_FOLDER/jenkins.pem"
```
 
## AzureADにアプリ登録する

AzureADのアプリ登録から

httpsのURLを作る
