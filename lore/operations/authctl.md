# lore-authctl による利用者・権限管理

旧 Authctl 資料と [実機の利用者登録記録](../work/server-193-account.md)
を基にした操作例。例は [bridge 構築手順](../setup/auth-bridge-setup.md) の path と実行 user を使う。
既存環境の path、権限、対象 binary の revision を確認し、`<...>` を置き換える。

> [!IMPORTANT]
> コマンドや引数は revision に依存する。特に旧資料の `key generate` と、実機構築例の
> `signing-key generate` は異なる。実行前に各 subcommand の `--help` を確認する。
> 既存 DB や signing key に対して `init-db`、鍵生成を安易に再実行しない。

## 1. 接続と対象を確認する

bridge host の管理者 shell で実行する。

```bash
AUTHCTL=/opt/lore/bin/lore-authctl
CONFIG=/opt/lore/config/lore-auth.yaml

sudo systemctl is-active lore-auth
sudo -u lore "$AUTHCTL" --config "$CONFIG" --help
sudo -u lore "$AUTHCTL" user --help
sudo -u lore "$AUTHCTL" group --help
sudo -u lore "$AUTHCTL" grant --help
sudo -u lore "$AUTHCTL" --config "$CONFIG" user list
sudo -u lore "$AUTHCTL" --config "$CONFIG" repo list
```

想定した service、user、repository が確認できない場合は、変更を止めて対象 host と config を
確認する。

## 2. Entra user を登録する

Entra 管理画面で tenant ID、user の object ID、email、display name を照合する。email claim が
未検証の場合、invitation のみに依存せず `<TENANT_ID>:<OBJECT_ID>` を bind する。
既存 user が `user list` にある場合は `user add` を省略する。

```bash
sudo -u lore "$AUTHCTL" --config "$CONFIG" user add \
  --email "<USER_EMAIL>" --name "<DISPLAY_NAME>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" user bind-identity \
  --idp entra --email "<USER_EMAIL>" --subject "<TENANT_ID>:<OBJECT_ID>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" user list
```

subject が別 user に bind 済みなら上書きせず、対象の object ID と既存 binding を調査する。
一時停止・再有効化は対象 revision の `user disable --help` / `user enable --help` を確認し、
対象と影響を確認してから行う。

## 3. repository grant を設定・確認する

repository が登録済みであることを確認し、必要な最小 role を付与する。

```bash
sudo -u lore "$AUTHCTL" --config "$CONFIG" grant list "<REPOSITORY>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" grant add \
  "user:<USER_EMAIL>" "<REPOSITORY>" writer
sudo -u lore "$AUTHCTL" --config "$CONFIG" check \
  "<USER_EMAIL>" "<REPOSITORY>" write
```

`check` の `allow` を確認する。結果は bridge の認可判定であり、実際の client による login、
clone、必要に応じた承認済み場所への write の確認とは別である。grant を外すときは
`grant remove --help`、対象 grant、影響範囲を確認してから実行する。

## 4. group と runner の CIDR

以下は Service Account を group に所属させ、runner の source CIDR と repository 権限を設定
する例である。`<USER_ID>` は bridge user ID、`<RUNNER_CIDR>` は **実測した**送信元 CIDR。

```bash
sudo -u lore "$AUTHCTL" --config "$CONFIG" group add "<GROUP>" \
  --description "CI runners"
sudo -u lore "$AUTHCTL" --config "$CONFIG" group member add "<GROUP>" "<USER_ID>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" group network-cidr add "<GROUP>" "<RUNNER_CIDR>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" group network-cidr list "<GROUP>"
sudo -u lore "$AUTHCTL" --config "$CONFIG" grant add \
  "group:<GROUP>" "<REPOSITORY>" writer
sudo -u lore "$AUTHCTL" --config "$CONFIG" check "<USER_ID>" "<REPOSITORY>" write
```

既存 group を使う場合は作成を省略し、既存 membership、CIDR、grant を確認する。Service Account の
network 判定には、nginx が実際の接続元を trusted proxy metadata として渡す必要がある。
実機例と失敗時の CIDR 修正は [215 の作業記録](../work/server-215-20261022-03.md) を参照する。

## 5. Service Account と secret

対象 revision の `service-account add --help` と `rotate --help` を確認する。
`add` / `rotate` の出力には secret が含まれるため、共有 terminal、shell history、CI log、
repository、chat に残さない。安全な方法で credential store に登録する。
rotation では旧 secret が直ちに無効になる実装を前提に切替を計画し、利用するすべての
credential store 更新後に login と clone を確認する。

CI での実操作例と検証記録は [Service Account の作業記録](../work/server-193-service-account.md)
を参照する。手動 token 発行も credential を生成するため、必要な検証環境でのみ使い、
対象 revision の `--help` と出力先を確認する。
