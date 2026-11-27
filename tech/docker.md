# dockerコマンドをインストール

## docker cliのインストール

```
# 管理者で実行する
winget install Docker.DockerCLI
```
```
# たぶん、ここにインスコされる
C:\Users\<user-folder>\AppData\Local\Microsoft\WinGet\Links\docker.exe
```

C:\Program Files\

以下にDockerフォルダを作り、落としてきた `docker.exe` をコピーする

※ `dockerd.exe` はコピーしない事

## docker compose コマンドのインストール

https://github.com/docker/compose

release を見る → 最新の `docker-compose-windows-x86_64.exe` を落とす

C:\Program Files\ 

以下に、cli-pluginsというフォルダを作る

落としてきた `docker-compose-windows-x86_64.exe` を docker-compose.exe　名前を変えて保存

## 環境変数を追加する

```
C:\Program Files\Docker
C:\Program Files\Docker\cli-plugins
```
path通ってるか確認する

```
PS C:\Users\ueno.s\Desktop> docker --version
Docker version 29.6.0, build fb59821
```

```
PS C:\Users\ueno.s\Desktop> docker compose version
Docker Compose version v5.2.0
```

Version情報帰ってくればOK
