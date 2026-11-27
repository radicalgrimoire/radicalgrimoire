# これを使う

piceaTech/node-gitlab-2-github
https://github.com/piceaTech/node-gitlab-2-github

Node.jsのプロジェクトを使って移植できます。

# 使い方

## NVM のインストール

https://qiita.com/asahina820/items/66c2289d736e30101e94

NVM for Windowsの項目を確認

nvm-windows
https://github.com/coreybutler/nvm-windows

> https://github.com/coreybutler/nvm-windows/releases

Githubからnvm-setup.zipをダウンロードしてインストール

## nvmからnode.jsのインストール

node.jsインストール

```
nvm install 20.2.3
```



# 実際に動かしてみる

## 動かすために必要なGitlabのバージョン確認

12.10.14より後のバージョンであることが必要。


## GitLab と Github 両方のアクセストークンの設定

割愛

## 設定ファイルの編集

```
  gitlab: {
    url: '',
    token: '',
    projectId: 0,
    （略）
},
```

* url
gitlabのURL。トップURLでOK
* token
gitlab側で作成したアクセストークン
* projectId
0の状態で実行すると、Gitlab側のリポジトリのプロジェクトID一覧が表示される

他はデフォでもOK


```
  github: {
    baseUrl: 'https://github.com',
    apiUrl: 'https://api.github.com',
    owner: '',
    ownerIsOrg: ,
    token: '',
    token_owner: '',
    repo: '',
    recreateRepo: false,
  },

```

* owner リポジトリの所有者
* ownerIsOrg リポジトリ所有者は組織かどうか。組織だったらtrue
* token
githubのアクセストークン
* token_owner
トークンのアカウント
* repo
リポジトリ名称