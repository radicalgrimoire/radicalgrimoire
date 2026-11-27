# 172.20.12.193: CI Service Account による Lore 利用

Jenkins や GitHub Actions など、ブラウザーを使う OIDC login ができない実行環境から
Lore を利用するための運用手順である。

`lore-auth-bridge` の Service Account は既存の bridge user として扱われる。OIDC
external identity は持たず、`client_id:client_secret` を bootstrap credential として
bridge に渡す。bridge は credential と送信元 CIDR を検証して短命の認証 token を発行し、
Lore CLI は通常どおり repository-scoped authorization token を交換して利用する。

Service Account secret を Lore Server に送信してはならない。`lore auth login` の
`--auth-url` には bridge の gRPC endpoint を指定する。

## 前提条件

- `lore-auth-bridge` に Service Account 実装を含む binary が deploy 済みである。
- bridge host `172.20.12.193` の HTTPS endpoint は次のとおりである。

  | 用途 | Endpoint |
  | --- | --- |
  | HTTP health / JWKS | `https://172.20.12.193:8080` |
  | gRPC token exchange | `https://172.20.12.193:8081` |
  | Lore remote | `lore://172.20.12.193:41337` |

- 実行 runner の固定送信元 IP または CIDR が分かっている。
- runner が bridge certificate を信頼している。
- Service Account を操作する管理者は bridge host へ SSH 接続できる。

## Service Account を作成する

bridge host で `lore-authctl` を実行する。`add` は user ID、client ID、secret を
tab 区切りで一度だけ標準出力へ返す。

```bash
ssh mgs@172.20.12.193

/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  service-account add \
  --client-id jenkins-release \
  --name "Jenkins Release"
```

出力の三列目だけを、CI platform の secret store に登録する。repository、workflow、
runner log、chat、shell history に secret を保存・出力してはならない。

```text
<service-account-user-id>    jenkins-release    <client-secret>
```

作成直後に credential を更新する場合は、`rotate` を実行して返された新しい secret に
secret store を更新する。旧 secret は直ちに無効になる。

```bash
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  service-account rotate \
  --client-id jenkins-release
```

`client_id` は ASCII 英数字、`.`, `-`, `_` だけを使用する。secret の形式は
`client_id:client_secret` であり、区切り文字を含む ID や secret は利用しない。

## network と repository 権限を付与する

Service Account user ID を既存の group に追加し、その group に runner の CIDR と
repository grant を付与する。Service Account 自身へ例外的な direct grant を増やさず、
通常の人間ユーザーと同じ group / ReBAC の権限設計を利用する。

GitHub Actions runner `172.20.16.41` に対する現在の例は次のとおりである。

| 項目 | 値 |
| --- | --- |
| Group | `github-actions-runners` |
| CIDR | `172.20.16.41/32` |
| Service Account | `jenkins-release` |
| Repository | `gamestudio/tc_sample_project` |
| Role | `writer` |

付与後、bridge の判定結果を確認する。

```bash
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  check "Jenkins Release" "gamestudio/tc_sample_project" write
```

`allow` が返ることを確認する。CIDR が未設定、または source IP がどの所属 group の CIDR
にも一致しない Service Account login は拒否される。

## gRPC proxy で送信元 IP を渡す

bridge の CIDR 判定は、nginx が loopback 経由で gRPC を proxy する場合に
`x-lore-client-ip` metadata を必要とする。`/etc/nginx/sites-enabled/lore-auth` の
`8081` gRPC locations に次を設定する。

```nginx
grpc_set_header x-lore-client-ip $remote_addr;
```

設定変更後は必ず syntax check を通して reload する。

```bash
sudo nginx -t
sudo systemctl reload nginx
```

外部 client から任意の forwarded address を信用してはならない。この設定は nginx が
受け取った TCP peer address を、loopback 上の trusted proxy と bridge 間だけで渡す。

## Windows runner に bridge certificate を信頼させる

runner certificate の作成、配布、更新は
[172.20.12.193: bridge TLS certificate の運用](./server-193-bridge-tls.md) に従う。
TLS verification を無効化する設定や `--insecure` を CI workflow に追加してはならない。

## GitHub Actions workflow

`gs-dev-platform-team/gspcd954` の
[`lore-service-account-test.yml`](https://github.com/gs-dev-platform-team/gspcd954/blob/main/.github/workflows/lore-service-account-test.yml)
は repository secret `LORE_JENKINS_RELEASE_CLIENT_SECRET` を使用する。

login は次の形にする。

```powershell
& $env:LORE_CLI auth login `
  --token-type service-account `
  --token "${env:LORE_CLIENT_ID}:$env:LORE_CLIENT_SECRET" `
  --auth-url https://172.20.12.193:8081 `
  lore://172.20.12.193:41337
```

clone、commit、push には Service Account secret や明示的な token option を渡さない。
`lore auth login` で token store に保存した通常の token を Lore CLI が使う。

現在の検証 workflow は clone destination を
`D:\Projects\Watch\tc_sample_project` に固定しており、既存 directory がある場合は
削除・上書きせず失敗する。次回の書き込み job でも毎回 login を行うこと。認証 token
store は runner temporary directory にあり、job 終了時に削除される。

## 受入確認

1. runner から workflow を `workflow_dispatch` で実行する。
2. `Authentication successful` が出力されることを確認する。
3. destination に `.lore` directory が作成されることを確認する。
4. 必要に応じて、専用の検証 repository で writer 権限による commit / push を確認する。
   既存の shared repository にテスト revision を残す場合は、事前に担当者の承認を得る。
5. bootstrap secret を一時 file に保存した場合は、CI secret の動作確認後に安全に削除する。

## 実施済みの検証

2026-10-21 に `jenkins-release` を使用して、GitHub Actions self-hosted runner
`172.20.16.41` から通常の Lore CLI login と
`gamestudio/tc_sample_project` の clone が成功した。検証 workflow run:

- <https://github.com/gs-dev-platform-team/gspcd954/actions/runs/39583565638>
- <https://github.com/gs-dev-platform-team/gspcd954/actions/runs/39584094912>

## 関連資料

- [172.20.12.193: Lore アカウントの作成](./server-193-account.md)
- [LORE Server の更新](./server-193-update.md)
- [lore-auth-bridge Service Account 実装](https://github.com/radicalgrimoire/lore-auth-bridge/commit/ee81aa6)
