# WSL2 + Ubuntu + Docker Engine 構築メモ

## 概要

WSL2 上の Ubuntu に Docker Engine を入れ、Windows 側からも Docker コマンドを使えるようにするための手順メモです。

## 前提

- Windows で WSL2 が使える状態であること
- 管理者権限で PowerShell を起動できること

## WSL に入る

PowerShell から次のコマンドで WSL の Ubuntu を起動できます。

### WSL を起動

```powershell
wsl -d Ubuntu
```

root で入る場合は次のようにします。

```powershell
wsl -d Ubuntu -u root
```

---

## 1. WSL2 をインストール

管理者 PowerShell で実行します。

```powershell
wsl --install Ubuntu
```

インストール後は PC を再起動してください。

---

## 2. systemd を有効化

WSL の Ubuntu を起動します。

```powershell
wsl -d Ubuntu
```

設定ファイルを編集します。

```bash
sudo vim /etc/wsl.conf
```

内容は次のようにします。

```ini
[boot]
systemd=true
```

その後、WSL を再起動します。

```powershell
wsl --shutdown
```

---

## 3. Docker Engine を Ubuntu にインストール

### 3-1. 依存パッケージをインストール

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
```

### 3-2. Docker の GPG キーを登録

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 3-3. Docker リポジトリを追加

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 3-4. Docker Engine をインストール

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3-5. Docker を systemd で起動

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

### 3-6. sudo なしで Docker を使う

```bash
sudo usermod -aG docker $USER
```

WSL を再起動するか、ログアウトして再ログインしてください。

---

## 4. Windows から WSL の Docker Engine を利用する

### 4-1. socat をインストール

```bash
sudo apt install -y socat
```

### 4-2. Docker ソケットを TCP で公開

最も簡単な方法は、起動時に次を実行することです。

```bash
sudo socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock
```

バックグラウンド実行する場合は次のようにします。

```bash
sudo socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock &
```

### 4-3. Windows 側で環境変数を設定

PowerShell で次を実行します。

```powershell
setx DOCKER_HOST tcp://localhost:2375
```

その後、PowerShell を再起動してください。

### 4-4. systemd サービスとして登録する場合

```bash
sudo vim /etc/systemd/system/socat-docker.service
```

内容は次のとおりです。

```ini
[Unit]
Description=Socat bridge for Docker (TCP 2375 -> Unix socket)
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable socat-docker
sudo systemctl start socat-docker
sudo systemctl status socat-docker
```

---

## 5. 動作確認

### WSL 側

```bash
sudo systemctl status docker
```

### Windows 側

```powershell
docker --version
docker info
docker compose version
```

---

## 6. Ubuntu イメージのバックアップと復元

```powershell
wsl --export Ubuntu E:\wsl\ubuntu.tar
wsl --unregister Ubuntu
wsl --import Ubuntu E:\wsl\Ubuntu E:\wsl\ubuntu.tar
```

---

## 7. 補足

- 変更を反映するには WSL の再起動が必要な場合があります。
- Docker の動作に問題がある場合は、まず `systemctl status docker` と `docker info` で状態を確認すると確認しやすいです。
