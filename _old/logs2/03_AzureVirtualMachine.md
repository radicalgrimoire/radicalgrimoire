# HDD関係の作業

* [Linux VM へのディスクの追加](https://learn.microsoft.com/ja-jp/azure/virtual-machines/linux/add-disk?tabs=ubuntu)
* [Linux VM の仮想ハード ディスクを拡張する](https://learn.microsoft.com/ja-jp/azure/virtual-machines/linux/expand-disks?tabs=ubuntu)

# デフォルトエディターの変更

vim のインストール
```
sudo apt update -qy
sudo apt install -y vim
```

デフォルトエディターをvimに変更
```
sudo update-alternatives --set editor /usr/bin/vim.basic
```

# ユーザーの追加

* dockerユーザーの追加

```
sudo adduser docker
```

* visudoでroot昇格できるようにしておく
```
docker  ALL=(ALL:ALL) NOPASSWD: ALL
```


# dockerインストール
https://docs.docker.com/engine/install/ubuntu/

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
```
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

# Dockerの稼働フォルダを変更する

* daemon.jsonを作成する

```
# 作成する場所
vi /etc/docker/daemon.json
```
```
{
 "data-root": "/datadrive/docker"
}
```