# 172.20.12.215: 未完了作業

## TLS certificate の計画更新

### 期限

- 計画開始期限: **2027-09-01**
- 現行 certificate の失効日時: **2027-10-19 03:13:23 UTC**

### 現在の状態

`/opt/lore/certs/lore-server.crt` は `172.20.12.215` 用の自己署名 TLS server
certificate である。

| 項目 | 値 |
| --- | --- |
| Subject / issuer | `CN=172.20.12.215` |
| SAN | `IP:172.20.12.215`, `DNS:localhost`, `IP:127.0.0.1` |
| SHA-256 fingerprint | `96:4E:72:9A:CB:34:AF:44:89:8D:C7:83:B9:EA:CB:2B:F9:2E:8C:9F:81:69:05:95:55:70:99:97:18:E0:6B:6A` |

現時点では更新しない。既存の Lore client はこの certificate を Windows の Trusted Root
store に登録しているため、certificate / private key を更新すると、新 certificate を
trust していない利用者は Lore login、clone、pull、push ができなくなる。

### 更新時の手順

1. 新 certificate と private key を作成する。SAN に `172.20.12.215`、`localhost`、
   `127.0.0.1` を含める。
2. 新しい public certificate を、既存の利用者と CI runner の Local Machine Trusted Root
   store へ先に追加する。
3. 全利用者・runner への配布完了を確認する。
4. `/opt/lore/certs/lore-server.crt` と `/opt/lore/certs/lore-server.key` を新しい
   key pair へ切り替える。
5. `lore-auth`、nginx、loreserver を restart し、Entra login、Lore clone、CI
   Service Account login を確認する。
6. 旧 certificate は、新 certificate での全接続を確認してから trust store から削除する。

詳細は [bridge TLS certificate の運用](./server-193-bridge-tls.md) を 215 の endpoint と
certificate path に読み替えて実施する。

### 実行コマンド

以下は **2027-09-01 以降**に実行する。作業を始める前に、215 を利用するすべての
Windows client と CI runner を洗い出す。

#### 1. 新しい 10 年 certificate を生成する

215 へ接続して実行する。private key を server 外へコピーしてはならない。

```bash
ssh mgs@172.20.12.215

STAMP="$(date -u +%Y%m%dT%H%M%SZ)-certificate-renewal"
NEXT_DIR="/home/mgs/lore-transfer/$STAMP"
install -d -m 0700 "$NEXT_DIR"

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
  -subj "/CN=172.20.12.215" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "subjectAltName=IP:172.20.12.215,DNS:localhost,IP:127.0.0.1" \
  -keyout "$NEXT_DIR/lore-server.key" \
  -out "$NEXT_DIR/lore-server.crt"

chmod 0600 "$NEXT_DIR/lore-server.key"
chmod 0644 "$NEXT_DIR/lore-server.crt"

openssl x509 -in "$NEXT_DIR/lore-server.crt" -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName
```

出力で `CN=172.20.12.215`、SAN、10 年後の expiry を確認する。

#### 2. 切替前に全 Windows client / runner へ配布する

client ごとに、管理者 PowerShell で実行する。Jenkins が Windows service account で
動く場合も、Current User ではなく Local Machine store に追加する。

```powershell
$certificatePath = "$env:TEMP\lore-server-215-next.pem"

scp mgs@172.20.12.215:~/lore-transfer/<STAMP>/lore-server.crt $certificatePath
certutil.exe -addstore -f Root $certificatePath

Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object Subject -eq 'CN=172.20.12.215'

Remove-Item -LiteralPath $certificatePath -Force
```

`<STAMP>` は手順 1 で作成した directory name に置き換える。全 client / runner に
import できるまで、215 の active certificate を切り替えない。

#### 3. certificate を切り替える

215 で実行する。既存 key pair は archive に保存する。

```bash
STAMP="$(date -u +%Y%m%dT%H%M%SZ)-certificate-renewal"
ARCHIVE="/opt/lore/archive/$STAMP"
NEXT_DIR="/home/mgs/lore-transfer/<GENERATION-STAMP>"

sudo install -d -o root -g root -m 0700 "$ARCHIVE"
sudo cp -p /opt/lore/certs/lore-server.crt \
  /opt/lore/certs/lore-server.key "$ARCHIVE/"
sudo sh -c "sha256sum '$ARCHIVE/lore-server.crt' '$ARCHIVE/lore-server.key' \
  > '$ARCHIVE/SHA256SUMS'"

sudo install -o mgs -g mgs -m 0644 \
  "$NEXT_DIR/lore-server.crt" /opt/lore/certs/lore-server.crt
sudo install -o mgs -g mgs -m 0600 \
  "$NEXT_DIR/lore-server.key" /opt/lore/certs/lore-server.key

sudo nginx -t
sudo systemctl restart lore-auth
sudo systemctl restart loreserver
sudo systemctl reload nginx
sudo systemctl is-active lore-auth loreserver nginx
```

`<GENERATION-STAMP>` は手順 1 の `<STAMP>` を指定する。nginx configuration check が
失敗した場合は reload せず、archive の key pair を戻して原因を調査する。

#### 4. 切替を検証する

215 で active certificate と各 service を確認する。

```bash
openssl x509 -in /opt/lore/certs/lore-server.crt -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName

curl --fail --cacert /opt/lore/certs/lore-server.crt \
  https://172.20.12.215:8080/healthz
curl --fail http://127.0.0.1:18080/.well-known/jwks.json
sudo ss -ltnp | grep -E ':(18080|18081|41337|41339)\b'
```

少なくとも 1 台の Windows Lore client と、Jenkins runner から login と clone を確認する。
Service Account 導入後であれば、Jenkins からの `service-account` token exchange も確認する。

#### 5. 旧 certificate の trust を削除する

新 certificate での接続が全 client / runner から確認できるまで削除しない。削除する場合は、
各 Windows client / runner の管理者 PowerShell で旧 thumbprint を指定する。

```powershell
certutil.exe -delstore Root `
  964E729ACB34AF44898DC783B9EACB2BF92E8C9F816905955570999718E06B6A
```
