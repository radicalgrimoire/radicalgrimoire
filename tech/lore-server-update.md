# LORE Server の更新

[LORE Server の構築・運用](./lore-server.md) で永続 store、certificate、systemd unit が
設定済みであることを前提に、`172.20.12.193` の Lore Server を公開 release へ更新する。

## Lore 0.10.1 の配置

この host には Rust/Cargo を前提にしない。公式 GitHub Release の
`x86_64-unknown-linux-gnu` archive を使用する。

```bash
export LORE_VERSION=v0.10.1
export RELEASE_DIR="/datadrive/lore/releases/${LORE_VERSION}"
sudo install -d -o root -g root -m 0755 "$RELEASE_DIR"

curl --fail --location --retry 3 \
  --output /tmp/loreserver.tar.gz \
  "https://github.com/EpicGames/lore/releases/download/${LORE_VERSION}/loreserver-${LORE_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
curl --fail --location --retry 3 \
  --output /tmp/lore.tar.gz \
  "https://github.com/EpicGames/lore/releases/download/${LORE_VERSION}/lore-${LORE_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

sudo tar -xzf /tmp/loreserver.tar.gz -C "$RELEASE_DIR"
sudo tar -xzf /tmp/lore.tar.gz -C "$RELEASE_DIR"
sudo chown -R root:root "$RELEASE_DIR"
sudo chmod 0755 "$RELEASE_DIR/loreserver" "$RELEASE_DIR/lore"
"$RELEASE_DIR/loreserver" --version
"$RELEASE_DIR/lore" --version
rm -f /tmp/loreserver.tar.gz /tmp/lore.tar.gz
```

`v0.10.1` の実行結果は以下になる。

```text
loreserver 0.10.1
lore 0.10.1+1476-lore_v0.10.1__urc_main
```

## 更新手順

### 1. 事前確認

```bash
sudo systemctl is-active lore lore-auth-bridge
curl -fk https://172.20.12.193:8080/healthz
curl -fk https://172.20.12.193:8080/.well-known/jwks.json
sudo test -d /datadrive/lore/data/store/immutable
sudo test -d /datadrive/lore/data/store/mutable
```

`lore` と `lore-auth-bridge` が active、health と JWKS が HTTP 200 であることを確認する。

### 2. recovery set を作成する

Lore data、Lore config、bridge data、bridge signing key、bridge config は同じ時点の
recovery set として保存する。

```bash
export BACKUP_ROOT=/datadrive/lore-backups
export BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%dT%H%M%SZ)-pre-upgrade"

sudo systemctl stop lore
sudo systemctl stop lore-auth-bridge
sudo systemctl is-active lore lore-auth-bridge

sudo install -d -m 0700 "$BACKUP_DIR"
sudo rsync -aHAX --numeric-ids /datadrive/lore/data/store/ "$BACKUP_DIR/store/"
sudo rsync -aHAX --numeric-ids /datadrive/lore/config/ "$BACKUP_DIR/lore-config/"
sudo rsync -aHAX --numeric-ids /home/mgs/lore-auth/data/ "$BACKUP_DIR/bridge-data/"
sudo rsync -aHAX --numeric-ids /home/mgs/lore-auth/keys/ "$BACKUP_DIR/bridge-keys/"
sudo install -m 0600 /home/mgs/lore-auth/lore-auth.yaml "$BACKUP_DIR/lore-auth.yaml"
sudo sha256sum /datadrive/lore/bin/lore /datadrive/lore/bin/loreserver \
  | sudo tee "$BACKUP_DIR/binaries.sha256"
```

> 新版 server が store へ write した後は、binary だけを旧版へ戻してはいけない。
> rollback する場合は store、bridge data、bridge key、設定を同じ backup から戻す。

### 3. binary を切り替える

`RELEASE_DIR` は前節で検証済みの archive 展開先とする。

```bash
sudo install -m 0755 /datadrive/lore/bin/lore \
  "$RELEASE_DIR/lore.previous"
sudo install -m 0755 /datadrive/lore/bin/loreserver \
  "$RELEASE_DIR/loreserver.previous"

sudo install -o root -g root -m 0755 \
  "$RELEASE_DIR/lore" /datadrive/lore/bin/lore
sudo install -o root -g root -m 0755 \
  "$RELEASE_DIR/loreserver" /datadrive/lore/bin/loreserver
```

### 4. bridge を先に起動してから Lore Server を起動する

```bash
sudo systemctl start lore-auth-bridge
curl -fk https://172.20.12.193:8080/healthz
curl -fk https://172.20.12.193:8080/.well-known/jwks.json

sudo systemctl start lore
sudo systemctl status lore-auth-bridge lore --no-pager
sudo journalctl -u lore -n 100 --no-pager

/datadrive/lore/bin/lore --version
/datadrive/lore/bin/loreserver --version
```

Lore Server が `active` になり、port `41337` と `41339` を listen していることを確認する。

```bash
sudo ss -lnt | grep -E ':(41337|41339)\b'
```

## 受入確認

更新後の client は再ログインする。Lore 0.9 以降は認証 token store の形式が変わっており、
旧 client の token を自動移行しない。

```powershell
lore auth login lore://172.20.12.193:41337
lore repository list lore://172.20.12.193:41337 --remote --no-pager
```

repository 作成、clone、commit、push を実行する。auth bridge が repository resource を
作成しても、作成者への grant が自動作成されない場合がある。その場合は明示的に
`writer` grant を追加する。

```bash
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  grant add "user:<USER-UUID>" "organization/repository" writer

/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  check <user-email> organization/repository read
/home/mgs/lore-auth/bin/lore-authctl \
  --config /home/mgs/lore-auth/lore-auth.yaml \
  check <user-email> organization/repository write
```
