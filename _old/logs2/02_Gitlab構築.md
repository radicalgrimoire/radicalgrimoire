# 参考記事

* https://qiita.com/rururu3/items/88e7688c5eec9ae1a68c
* https://qiita.com/myoshimi/items/37c90c2a63dca295edb4
* https://docs.gitlab.com/ee/integration/saml.html?tab=Docker

```
openssl x509 -sha1 -fingerprint -noout -in gitlab-sso.pem
SHA1 Fingerprint=AA:BB:CC:DD:EE:AA:BB:CC:DD:EE:AA:BB:CC:DD:EE
```

# SSO設定とか

```
*GITLAB_OMNIBUS_CONFIG* の設定項目簡易解説

* external_url
GitlabのURLを設定。httpsでのURLを設定

* gitlab_rails['time_zone'] = 'Asia/Tokyo'
タイムゾーンの設定 Asia/Tokyo に

* gitlab_rails['gitlab_shell_ssh_port'] = 10022
SSHでリポジトリを取得する際のポート

* gitlab_rails['lfs_enabled'] = true
GitLFS機能の有効化

* nginx['redirect_http_to_https'] = true
httpをhttpsにリダイレクトする

* nginx['listen_port'] = 9080
* registry_nginx['listen_port'] = 9080
nginxのlistenport

* nginx['listen_https'] = false
* registry_nginx['listen_https'] = false
httpsのlistenするかどうか。

* letsencrypt['enable'] = false
Gitlabの機能を使ってletsencryptから証明書を取得する

* gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']

* gitlab_rails['omniauth_block_auto_created_users'] = false
* gitlab_rails['omniauth_auto_link_saml_user'] = true


---

Gitlab + SSO構築のメモ

* AzureEntraIDアプリケーションの作成
* EntraIDアプリケーションの設定
* カギの設定