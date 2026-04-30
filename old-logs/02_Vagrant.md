# Vagrant のインストール

公式サイト `https://www.vagrantup.com`  


インストールが終わったら`vagrant -v`と入力して、  
インストールしたvagrantのバージョンが帰ってくるかどうかを確認する。

```
$ vagrant -v  
Vagrant 2.1.1
```

# Oracle VirtualBoxのインストール

http://www.oracle.com/technetwork/server-storage/virtualbox/downloads/index.html?ssSourceSiteId=otnjp  

自分のOS種類に応じてダウンロードする。

# Boxを追加する

boxファイルはココらへんを探す
```
サイト：
http://www.vagrantbox.es  
https://app.vagrantup.com
```

```
box追加コマンド例
vagrant box add [vagrantのbox名] [boxのURL]  
```

# Vagrantfileを作成する

適当なフォルダを作りコンソールを立ち上げて、入力

```
$ vagrant init
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```
作成したVagrantfileを編集


# 起動

windowsのコマンドプロンプト等で  
Vagrantfileがあるフォルダで実行。
```
vagrant up
```

# 疎通確認

windowsのコマンドプロンプト等で  
Vagrantfileがあるフォルダで実行。

```
vagrant ssh
```
ssh で入れたら疎通完了

***

トラブルなど

* DockerDesktopのHyperVアダプターが原因でVagrantupできない

DockerDesktopが原因。一緒にHyperVアダプターが入ってしまう  
DockerDesktopをアンインストールして、DockerToolBoxをインストールする。

https://github.com/docker/toolbox/  
https://github.com/docker/toolbox/releases

「プログラムと機能」⇒「Windowsの機能の有効化または無効化」から「Hyper-V」にチェックを入れる。
もし「Hyper-V プラットフォーム」にチェックが入れられない場合、BIOSの設定で仮想化支援機能(Intel VT-d)をオンにする必要がある。

　
* vagrantupできない

~~Vagrantのバージョンが1.9.6より後のバージョンをインストールする場合に~~  
~~仮想環境を動かすコマンド実行（vagrant up）時に動作しない可能性がある~~  
~~この場合は、PowerShellのバージョンを上げて対応。~~  
~~※PowerShellのバージョンの上げ方はリンク先参照~~  
~~https://qiita.com/nobb_hero/items/3422b37ba2e9e3299680~~  

Windows10のPCならそもそも対応不要  

* vagrant マウント時にエラー  
https://qiita.com/chubura/items/4166585cf3f44e33271d
https://qiita.com/ozawan/items/9751dcfd9bd4c470cd82

```
vagrant plugin install vagrant-vbguest
```
