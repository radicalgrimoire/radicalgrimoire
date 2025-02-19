# DockerToolbox インストール手順

OS的にDockerDesktopがインストールできない！！困った！！人向け

<br />

## 各種インストールexeをインストール

* DockerToolbox  

Githubの[docker/toolbox](https://github.com/docker/toolbox)の[release](https://github.com/docker/toolbox/releases)から最新のインストールexeを入手する  
> https://github.com/docker/toolbox/releases

* OracleVirtualbox

Oracleから入手  
> https://www.oracle.com/jp/virtualization/technologies/virtualbox/downloads.html  
>> https://www.oracle.com/jp/virtualization/technologies/vm/downloads/virtualbox-downloads.html  

2つを入手して自分のPCにインストール

<br />

## StorageDriverを変更する

/etc/systemd/system/docker.service.d/10-machine.conf

こことかを見る。

## Kitematic (Alpha)を起動する

DockerHubへのログイン画面が出たらOK  
お疲れ様でした。
<br />

#### (tips)途中でエラーになったら

* リトライ or Use VirtualBoxみたいなボタンが出た  
⇒ Use VirtualBoxのボタンを押して再開

<br />

* Kitematicの起動時、100パーセントでDockerHubのログイン画面がでない  
⇒ gitbashを起動して、おもむろに `docker-machine ls` とコマンド入力する。

```
 x509: certificate has expired or is not yet valid
```

とかいうエラーだったら

```
[Git bash上で入力]
docker-machine regenerate-certs --client-certs default
```
これでOK

<br />

* Kitematicの起動時、99パーセントで止まる  
⇒ Windowsのユーザーフォルダ以下の `~/.ssh/config` を疑いましょう。

```
Host localhost
  ControlMaster no
  ControlPersist no
```

※参考:https://qiita.com/2k0ri/items/9a4b8d3ea95decd962e6