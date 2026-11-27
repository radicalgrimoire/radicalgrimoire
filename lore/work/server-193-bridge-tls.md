# 172.20.12.193: bridge TLS certificate の運用

`172.20.12.193` の `lore-auth-bridge` は、HTTP endpoint `:8080` と gRPC token
exchange endpoint `:8081` で同じ自己署名 TLS server certificate を使用する。この
document は certificate の作成、配布、更新手順を定める。

現在の certificate は次の性質を持つ。

| 項目 | 値 |
| --- | --- |
| Subject / issuer | `CN=172.20.12.193` |
| Subject Alternative Name | `IP:172.20.12.193`, `DNS:localhost`, `IP:127.0.0.1` |
| Basic constraint | `CA:FALSE` |
| 用途 | TLS Web Server Authentication |
| Certificate path | `/home/mgs/lore-auth/grpc/tls.crt` |
| Private key path | `/home/mgs/lore-auth/grpc/tls.key` |

これは独立 CA certificate ではなく、server certificate 自身を trust anchor として
Windows の Local Machine store に登録する運用である。

## 新しい certificate を作成する

certificate を更新する前に、[runner への配布](#windows-runner-へ配布する)を完了する
必要がある。新 certificate に切り替えた直後、未更新 runner からの gRPC login は TLS
verification error で失敗する。

bridge host に接続し、temporary directory で key pair を作成する。

```bash
ssh mgs@172.20.12.193

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj "/CN=172.20.12.193" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "subjectAltName=IP:172.20.12.193,DNS:localhost,IP:127.0.0.1" \
  -keyout "$WORKDIR/tls.key" \
  -out "$WORKDIR/tls.crt"

openssl x509 -in "$WORKDIR/tls.crt" -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName
```

出力の subject、issuer、SAN、validity、fingerprint を記録する。private key
`$WORKDIR/tls.key` を host 外へコピーしてはならない。

## Windows runner へ配布する

生成した certificate はまだ active ではない。runner ごとに新 certificate を
Local Machine の Trusted Root store へ import してから bridge を切り替える。

生成を実施する bridge host から管理用 Windows host へ certificate を copy する場合は、
host 上で一時的に certificate を保存し、copy 元 path を明示する。

```bash
install -m 0644 "$WORKDIR/tls.crt" /tmp/lore-auth-bridge-next-tls.crt
```

Windows の管理者 PowerShell で取得して import する。

```powershell
$certificatePath = "$env:TEMP\lore-auth-bridge-next-tls.pem"
scp mgs@172.20.12.193:/tmp/lore-auth-bridge-next-tls.crt $certificatePath

certutil.exe -addstore -f Root $certificatePath

Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object Subject -eq 'CN=172.20.12.193'

Remove-Item -LiteralPath $certificatePath -Force
```

GitHub Actions self-hosted runner は `NETWORK SERVICE` として動くため、Current User
store への import では不十分である。必ず Local Machine store を使用する。

全 runner への配布後、bridge host で一時 copy を削除する。

```bash
rm -f /tmp/lore-auth-bridge-next-tls.crt
```

## bridge と nginx を切り替える

全 runner の trust store 更新が済んだ後にだけ、新しい key pair を active path に
install する。`lore-auth-bridge` は `mgs:mgs`、nginx は certificate を read できる
必要がある。

```bash
sudo install -o mgs -g mgs -m 0644 \
  "$WORKDIR/tls.crt" /home/mgs/lore-auth/grpc/tls.crt
sudo install -o mgs -g mgs -m 0600 \
  "$WORKDIR/tls.key" /home/mgs/lore-auth/grpc/tls.key

sudo nginx -t
sudo systemctl restart lore-auth-bridge
sudo systemctl reload nginx

sudo systemctl is-active lore-auth-bridge nginx
openssl x509 -in /home/mgs/lore-auth/grpc/tls.crt -noout \
  -subject -issuer -dates -fingerprint -sha256 -ext subjectAltName
```

`lore-auth-bridge` と nginx が `active` であることを確認する。nginx configuration
check が失敗した場合は reload せず、原因を修正する。

## runner から検証する

runner で TLS trust と gRPC endpoint を確認してから、Service Account workflow を
実行する。

```powershell
Test-NetConnection 172.20.12.193 -Port 8081
Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object Subject -eq 'CN=172.20.12.193'
```

GitHub Actions の `Lore service account test` を実行し、`Authentication successful` と
clone 成功を確認する。`curl --insecure` の HTTP/1.1 成功は gRPC HTTP/2 の検証には
ならないため、受入確認に使わない。

## 現行 certificate を runner へ追加するだけの場合

certificate の更新をせず、現在 active な certificate を新しい runner に追加するだけ
なら、次を実行する。

```powershell
$certificatePath = "$env:TEMP\lore-auth-bridge-grpc-ca.pem"
scp mgs@172.20.12.193:/home/mgs/lore-auth/grpc/tls.crt $certificatePath
certutil.exe -addstore -f Root $certificatePath
Remove-Item -LiteralPath $certificatePath -Force
```

## 関連資料

- [CI Service Account による Lore 利用](./server-193-service-account.md)
- [LORE Server の更新](./server-193-update.md)
