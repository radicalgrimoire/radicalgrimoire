# JenkinsにSSOでログインする（AzureAD）

## 前提

jenkins公式のDockerイメージを使ってjenkinsを準備します。  
使うイメージタグは`jenkins:jenkins:latest`です  

# 1. JenkinsのSSL化対応

良い感じのDockerfileが見つかったのでこちらを採用。

> https://github.com/ravi2krishna/jenkins-ssl-docker

このDockerfileで使用しているイメージタグの内容を  
`jenkins/jenkins:latest`から`jenkins:jenkins:lts`に変更

## 1-1. Configのバックアップを取る

```
cp /var/lib/jenkins_home/config.xml /var/lib/jenkins_home/config.xml.bak
``` 
設定ミスったら、バックアップしたコンフィグから戻す  
<br />

# 2. AzureADにアプリ登録する

![add app](https://raw.githubusercontent.com/hexagrimoire/WorkNote/main/image/jenkins.image.01.png)

```
アプリケーション名：任意の名称
サポートされているアカウントの種類：シングルテナント

URI：
https://[https化したJenkinsのURL]/securityRealm/finishLogin
```

## 2-1. アプリ登録した物の設定を変更、APIのアクセス許可を追加する

委任されたアクセス許可  
`Directory.Read.All`, `User.Read`  

アプリケーションの許可  
`Directory.Read.All`  
  
これらを追加する  

**※追加したらクラウド管理者がAPI許可するのを忘れずに**  
<br />

## 2-2. 証明書とシークレットから、新しいシークレットを追加

`有効期限無し`で追加。説明入れるかどうかは任意  
追加したシークレットキーの値はどっかにメモしておく  
<br />

# 3. エンタープライズアプリケーション側の設定変更

アプリ登録で作成したJenkins接続用のAzureADアプリがエンタープライズアプリケーションとしても作成されているので  
エンタープライズアプリケーション側の設定の変更をする  

**ユーザーの割り当てが必要ですか?** が **いいえ**になっているので、**はい**に変える

これによりエンタープライズアプリケーション側で**ユーザーの割り当てた人だけ**がアクセスできるような状態になる

![エンタープライズアプリ変更](https://raw.githubusercontent.com/hexagrimoire/WorkNote/main/image/jenkins.image.03.png)
  
<br />

# 4. Azure ADプラグインをJenkinsに追加する

プラグインの追加は略

## 4-1. Jenkinsのグローバルセキュリティの変更
  
`Client ID:` AzureAD側で作成したアプリのアプリケーションIDを参照  
`Client Secret:` 作成したシークレット情報を入力  
`Tenant:` AzureAD側で作成したアプリのディレクトリ (テナント) IDを参照  

設定して`サクセス`と出たら認証OK。権限設定へ

## 4-2. Jenkinsグローバルセキュリティのアクセス権限設定

権限設定例

![権限設定例](https://raw.githubusercontent.com/hexagrimoire/WorkNote/main/image/jenkins.image.02.png)

これで認証設定OK