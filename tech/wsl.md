# WSL2 + Ubuntu + Docker Engine 構築メモ

## 目的

WSL2 上の Ubuntu に Docker Engine を導入し、Windows から Docker コマンドを使えるようにするための手順メモ
また、WSL2 上で動作する SSH や Docker コンテナを Windows 経由で外部公開するための基本手順もまとめる

## 前提

- Windows で WSL2 が利用できる状態
- 管理者権限で PowerShell を起動できる状態
- インターネット接続が可能

## WSL を起動

PowerShell から WSL の Ubuntu を起動

```powershell
wsl -d Ubuntu
```

root で起動する場合は次のようにする

```powershell
wsl -d Ubuntu -u root
```

---

## 1. WSL2 をインストール

管理者 PowerShell で実行

```powershell
wsl --install Ubuntu
```

インストール完了後は PC を再起動

---

## 2. systemd を有効化

WSL の Ubuntu を起動

```powershell
wsl -d Ubuntu
```

設定ファイルを編集

```bash
sudo vim /etc/wsl.conf
```

内容は次のようにする

```ini
[boot]
systemd=true
```

保存したら、WSL を再起動

```powershell
wsl --shutdown
```

その後、再度 WSL を起動

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

WSL を再起動するか、ログアウトして再ログイン

---

## 4. 動作確認

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

正常に動作していれば、Docker のバージョン情報とクライアント情報が表示される

---

## 5. WSL2 上のサービスを外部公開するための手順

WSL2 は外部ネットワークから直接見えない。Windows が NAT の出口となり、WSL2 のポートへ転送する構成が必要になる

この手順は SSH や Docker コンテナなど、WSL2 上で動くサービスに共通

### 5-1. WSL2 側でサービスが LISTEN していることを確認

WSL2 の Ubuntu 内で、対象サービスがポートを開いているか確認

例: SSH

```bash
sudo ss -lnpt | grep sshd
```

例: Docker コンテナ

```bash
docker ps
docker inspect <container> | grep -i "41337"
```

WSL2 内で `0.0.0.0:<port>` が LISTEN していれば、サービス自体は起動している

### 5-2. Windows 側で WSL2 の IP を確認

WSL2 の IP は起動ごとに変わるため、毎回確認が必要

```powershell
wsl hostname -I
```

例:

```text
172.24.138.15
```

この IP は WSL2 の本体側のアドレス。Docker の bridge ネットワークに割り当てられた 172.17.x / 172.18.x とは別物

### 5-3. Windows の portproxy でポート転送を設定

PowerShell を管理者権限で開き、ポート転送を設定

SSH の例: 2222 → 22

```powershell
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=172.24.138.15
```

LORE の例: 41337 / 41339

```powershell
netsh interface portproxy add v4tov4 listenport=41337 listenaddress=0.0.0.0 connectport=41337 connectaddress=172.24.138.15
netsh interface portproxy add v4tov4 listenport=41339 listenaddress=0.0.0.0 connectport=41339 connectaddress=172.24.138.15
```

設定内容を確認するには次を実行

```powershell
netsh interface portproxy show v4tov4
```

### 5-4. Windows ファイアウォールで対象ポートを開放

Windows が LISTEN していても、ファイアウォールでブロックされると接続が失敗する

SSH の例:

```powershell
New-NetFirewallRule -DisplayName "WSL2 SSH" -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow
```

LORE の例:

```powershell
New-NetFirewallRule -DisplayName "LORE 41337" -Direction Inbound -Protocol TCP -LocalPort 41337 -Action Allow
New-NetFirewallRule -DisplayName "LORE 41339" -Direction Inbound -Protocol TCP -LocalPort 41339 -Action Allow
```

### 5-5. Windows から接続テスト

外部公開前に、まず Windows 自身から接続できるか確認

SSH の例:

```powershell
ssh <user>@127.0.0.1 -p 2222
```

LORE の例:

```powershell
curl http://127.0.0.1:41339/health_check
```

Windows から通れば、外部からも通る可能性が高い

### 5-6. 外部からアクセス

外部 PC からは、Windows のグローバル IP を使ってアクセス

SSH の例:

```bash
ssh <user>@<global-ip> -p 2222
```

LORE の例:

```bash
lore repository list lore://<global-ip>:41337
```

### 5-7. WSL2 の IP が変わる問題への対処

WSL2 は起動ごとに IP が変わるため、portproxy の connectaddress を自動更新するスクリプトを用意すると安定する
必要になった時点で、PowerShell スクリプトで自動化する構成に切り替える

注意:
スクリプト実行後も、WSL 側のサービスが実際に起動しているかは別途確認が必要
wslにアクセス実行中のターミナルは落としてはいけない

### 5-8. まとめ

WSL2 上のサービスを外部公開するために必要なのは、次の 3 点

1. WSL2 内で対象サービスが LISTEN していること
2. Windows の portproxy で WSL2 の IP に転送すること
3. Windows ファイアウォールで対象ポートを開放すること

SSH も LORE も、構造は同じ

---

## 6. Ubuntu イメージのバックアップと復元

```powershell
wsl --export Ubuntu E:\wsl\ubuntu.tar
wsl --unregister Ubuntu
wsl --import Ubuntu E:\wsl\Ubuntu E:\wsl\ubuntu.tar
```

---

## 7. 補足

- 変更を反映するには WSL の再起動が必要な場合がある
- Docker の動作に問題がある場合は、まず `systemctl status docker` と `docker info` を確認すると原因を切り分けやすい
- WSL2 の IP が変わることがあるため、ポート転送設定は必要に応じて見直す
