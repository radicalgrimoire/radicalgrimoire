## ■ VSCodeのインストール

[公式サイト](https://code.visualstudio.com/) からインストール
<br />

## ■ LinuxマシンにDockerをインストール

Dockerユーザーを忘れずに追加する事
* [VirtualMachine](https://github.com/radicalgrimoire/radicalgrimoire/wiki/02_VirtualMachine)
<br />

## ■ dockerユーザーにSSHキーでログインできるように

[新しい SSH キーを生成して ssh-agent に追加する](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

```
ssh-keygen -t ed25519 -C "your_email@example.com"
mv id_ed25519.pub authorized_keys
chmod 600 authorized_keys
```

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
mv id_rsa.pub authorized_keys
chmod 600 authorized_keys
```

## ■ configに鍵の指定

```
Host 見分けのつけられる名前
  HostName <サーバーIP>
  User docker
  Port 22
  IdentityFile ~/.ssh/<鍵ファイル>
```
Configファイルを良い感じに編集して、

## リモートエクスプローラー から リモートにアクセスする

![リモートエクスプローラー](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/refs/heads/main/images/03_VSCode04.png)  

* リモートエクスプローラーの接続一覧から  
`現在のウィンドウで接続...` または `新しいウィンドウで接続...`  

## `><` ボタン から リモートにアクセスする

![image](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/refs/heads/main/images/03_VSCode01.png)  

![SSH](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/refs/heads/main/images/03_VSCode02.png)  

ホスト情報を入力してアクセスする

* ホストに接続するを入力
* 新規IPアドレスを入力からIPをいれる
* 確認のダイアログっぽいのが上にちっちゃく出るがOK（続行）を押す

# AttachShell からコンテナにアクセスする

![アクセス先](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/refs/heads/main/images/03_VSCode03.png)  

# 【アクセス後】プラグインDockerをインストール

※SSHアクセスした後にインストールを実行

リモートのDockerサービスにアクセスできるようになるので、コンテナを操作する