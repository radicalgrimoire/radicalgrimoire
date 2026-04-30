# インストール
## 必要なパッケージの追加
```
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```
## リポジトリの追加
```
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```
## インストール
```
sudo yum install docker-ce docker-ce-cli containerd.io
```
### ※旧バージョンのアンインストール
```
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```
## docker-machineのインストール
```
sudo curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine
sudo chmod +x /usr/local/bin/docker-machine
```
## docker-composeのインストール
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
### ※コマンドが見つからないといわれる
一例）visudoして、secure_pathに追加する
他、.bath_profileに追加でもなんでもいい。
```
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/local/bin:/usr/bin
```
# コンフィグの場所
```
vi /lib/systemd/system/docker.service
```
```
/etc/systemd/system/docker.service.d/10-machine.conf
```

* volumeの場所を調べる
```
docker inspect <コンテナID>
```

// portを開ける
```
firewall-cmd --add-port=2376/tcp --zone=public --permanent
firewall-cmd --reload
```