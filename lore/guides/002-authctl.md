# lore-authctl による利用者・権限管理

旧 Authctl 資料と [実機の利用者登録記録](../work/server-193-account.md)
を基にした操作例。例は [bridge 構築手順](../setup/lore-auth-bridge/README.md) の path と実行 user を使う。
既存環境の path、権限、対象 binary の revision を確認し、`<...>` を置き換える。

> [!IMPORTANT]
> コマンドや引数は revision に依存する。特に旧資料の `key generate` と、実機構築例の
> `signing-key generate` は異なる。実行前に各 subcommand の `--help` を確認する。
> 既存 DB や signing key に対して `init-db`、鍵生成を安易に再実行しない。

## 1. 接続と対象を確認する

bridge host の管理者 shell で実行する。

```bash
sudo systemctl is-active lore-auth
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml --help
sudo -u lore /opt/lore/bin/lore-authctl user --help
sudo -u lore /opt/lore/bin/lore-authctl group --help
sudo -u lore /opt/lore/bin/lore-authctl grant --help
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user list
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml repo list
```

想定した service、user、repository が確認できない場合は、変更を止めて対象 host と config を
確認する。

## 2. Entra user を登録する

Entra 管理画面で tenant ID、user の object ID、email、display name を照合する。email claim が
未検証の場合、invitation のみに依存せず `<TENANT_ID>:<OBJECT_ID>` を bind する。
既存 user が `user list` にある場合は `user add` を省略する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user add \
  --email "<USER_EMAIL>" --name "<DISPLAY_NAME>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user bind-identity \
  --idp entra --email "<USER_EMAIL>" --subject "<TENANT_ID>:<OBJECT_ID>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user list
```

subject が別 user に bind 済みなら上書きせず、対象の object ID と既存 binding を調査する。
一時停止・再有効化は対象 revision の `user disable --help` / `user enable --help` を確認し、
対象と影響を確認してから行う。

対象 revision の `entra_oid_tid` は token の `tid` と `oid` を subject とし、設定された
`required_tid` と異なる tenant を拒否する。同じ有効 user への同じ binding は冪等だが、
別 user に紐付く subject や無効 user への binding は拒否される。binding と監査は同一
transaction で確定する。email、UPN、表示名を永続 subject の代わりにしない。
確認済み email を使う別の登録経路は [Identity Provider と招待](../setup/lore-auth-bridge/012-identity-providers.md)
を参照する。

### 確認済み email による招待

bridge `a751711` では、管理 Web UI の招待機能は削除されているが、CLI の `user invite` は
利用できる。IdP が確認済み email を返し、対象 provider に
`trust.email_binding: verified_email_invitation` が設定されている場合の登録経路である。
設定を省略すると対象 revision の既定値は `disabled` で、招待は login 時に消費されない。

provider ID、対象 email、表示名と対象 DB を確認してから実行する。`<PROVIDER_ID>` は設定の
`identity_providers.providers` の key である。

```bash
sudo -u lore /opt/lore/bin/lore-authctl user invite --help
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user invite \
  --idp "<PROVIDER_ID>" --email "<USER_EMAIL>" --name "<DISPLAY_NAME>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml user list
```

この操作は user と pending invitation を登録するが、メールを送信せず、repository 権限の
付与や token の発行もしない。対象 user が IdP で login し、provider、issuer、確認済み email と
domain policy が一致した場合に identity binding が作成される。
`user list` の pending 表示だけでは login 完了を意味しない。対象 user の実際の login と、
必要な grant を設定した後の repository 操作も確認する。

IdP が未検証 email を返す場合、この招待は消費されない。未検証 email を本人確認に使わず、
Entra では上記の管理者確認済み tenant ID と object ID による binding を使う。
信頼設定と対象 revision の詳細は [Identity Provider と招待](../setup/lore-auth-bridge/012-identity-providers.md#確認済み-email-による招待)
を参照する。

## 3. repository grant を設定・確認する

repository が登録済みであることを確認し、必要な最小 role を付与する。

```bash
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml grant list "<REPOSITORY>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml grant add \
  "user:<USER_EMAIL>" "<REPOSITORY>" writer
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml check \
  "<USER_EMAIL>" "<REPOSITORY>" write
```

`check` の `allow` を確認する。結果は bridge の認可判定であり、実際の client による login、
clone、必要に応じた承認済み場所への write の確認とは別である。grant を外すときは
`grant remove --help`、対象 grant、影響範囲を確認してから実行する。

通常は Lore Server の ReBAC `CreateResource` により repository が bridge に登録される。
JWT の `resources[].resource_id` は repository 名ではなく `urc-{lore_repository_id}`。
`admin` は他人の lock 解除以外の操作も許可する可能性があるため、信頼できる主体に限定する。
grant 変更は発行済み authz token を即時失効させない。新しい認可情報を取得し、
対象 revision で実際の権限を確認する。

## 4. group と runner の CIDR

以下は Service Account を group に所属させ、runner の source CIDR と repository 権限を設定
する例である。`<USER_ID>` は bridge user ID、`<RUNNER_CIDR>` は **実測した**送信元 CIDR。
新規 Service Account は作成時に group を指定するため、その場合は group の作成と membership
追加を重複して実行しない。

```bash
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml group add "<GROUP>" \
  --description "CI runners"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml group member add "<GROUP>" "<USER_ID>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml group network-cidr add "<GROUP>" "<RUNNER_CIDR>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml group network-cidr list "<GROUP>"
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml grant add \
  "group:<GROUP>" "<REPOSITORY>" writer
sudo -u lore /opt/lore/bin/lore-authctl \
  --config /opt/lore/config/lore-auth.yaml check "<USER_ID>" "<REPOSITORY>" write
```

既存 group を使う場合は作成を省略し、既存 membership、CIDR、grant を確認する。Service Account の
network 判定には、nginx が実際の接続元を trusted proxy metadata として渡す必要がある。
実機例と失敗時の CIDR 修正は [215 の作業記録](../work/server-215-20261022-03.md) を参照する。

対象 revision では IPv4 / IPv6 の単一 address は `/32` / `/128` として登録され、
適用される group の CIDR は合算される。適用 CIDR が一つもない通常 user の login には
IP 制限がないが、Service Account の認証には一致する CIDR が必要である。変更は発行済み
token を無効化しない。

## 5. Service Account と secret

対象 revision の `service-account add --help` と `rotate --help` を確認する。
`add` / `rotate` の出力には secret が含まれるため、共有 terminal、shell history、CI log、
repository、chat に残さない。安全な方法で credential store に登録する。
rotation では旧 secret が直ちに無効になる実装を前提に切替を計画し、利用するすべての
credential store 更新後に login と clone を確認する。

CI での実操作例と検証記録は [Service Account の作業記録](../work/server-193-service-account.md)
を参照する。手動 token 発行も credential を生成するため、必要な検証環境でのみ使い、
対象 revision の `--help` と出力先を確認する。

## 6. 手動 token 発行と管理者の復旧

IdP を使わない検証や障害時の `token mint-authn` と repository scoped `token mint` は
別の操作である。[token 発行と device flow](../operations/005-token-flows.md) で安全な出力先と取扱いを
確認する。

管理者を誤って無効化した場合は対象 DB と user を確認してから `user enable` で復旧する。
IdP 障害時も host 上の管理 CLI を使った管理変更は可能で、対象 revision の CLI 書き込みは
監査付き adapter を通る。完全な disaster recovery を保証する手順ではないため、事前に
対象 revision と承認済み運用で検証する。
