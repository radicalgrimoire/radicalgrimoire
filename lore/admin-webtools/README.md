# bridge 管理 Web UI

旧管理 UI 資料を基にした手順。`/admin` の動作や内部 API は
bridge revision に依存する。この手順と例の access 制限は一般化したものであり、
実環境での通し検証は未実施。変更前に使用 revision の実装と現在の nginx 設定を確認する。

## ドキュメント

- [管理 UI へのログイン](001-login.md) — 管理者の準備とログイン。
- [repository](002-repositories.md) — 一覧、作成、権限、無効化。
- [user](003-users.md) — 登録、Entra identity、直接権限。
- [group](004-groups.md) — member と許可接続元。
- [管理ツール設定](005-settings.md) — Service Account、権限判定。
- [メンテナンスモード](006-maintenance.md) — 新規 token 発行の停止と注意事項。

## 1. 利用前の確認

- 管理者の Entra identity と bridge user が登録済みで、ブラウザー login ができる。
- `lore-auth.yaml` の `admin.admin_emails` に対象管理者の email を設定する。
  旧資料では空または未設定の場合 `/admin` は mount されず 404 を返す。
- 管理用ネットワークからのみ UI と**管理 API を含む全管理 endpoint** にアクセスできるよう、
  公開側の reverse proxy または network boundary で制限する。
- 認証済み管理者でも必要な最小権限で利用し、audit record を確認する。

`admin_allowed_peer_cidrs: ["127.0.0.1/32"]` は bridge が直接見る TCP peer の制限である。
nginx が loopback から proxy する場合、外部利用者も bridge からは nginx の loopback address
に見える。**この設定だけでは外部 client の送信元制限にはならない。**

## 2. nginx の公開境界を制限する

現在の [bridge 構築例](../setup/001-auth-bridge-setup.md#7-nginx-設定) は HTTP の `location /` を
bridge へ転送するため、そのままでは `/admin` に専用の送信元制限は設定していない。
UI を有効にする前に、管理者が利用する CIDR を確定し、対象 revision の全管理 endpoint と
nginx の location 優先順位を確認する。`/admin` 以外に管理 API が存在する場合は、それらも
同じ管理境界で制限する。特定できない場合は公開しない。

以下は `8080` server 内の `/admin` と `/admin/` 以下に制限を追加する例であり、
**他の管理 API の保護を保証しない**。`<ADMIN_CIDR>` は信頼できる管理端末の CIDR に置き換える。
既存の location や upstream proxy の構成も含めて確認する。

```nginx
location = /admin {
    allow <ADMIN_CIDR>;
    deny all;
    proxy_pass http://127.0.0.1:18080;
    proxy_set_header Host $host:$server_port;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

location ^~ /admin/ {
    allow <ADMIN_CIDR>;
    deny all;
    proxy_pass http://127.0.0.1:18080;
    proxy_set_header Host $host:$server_port;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

nginx の `$remote_addr` が管理端末の実際の送信元であることを確認する。手前に proxy や load
balancer がある場合、クライアントが指定した `X-Forwarded-For` を無条件に信頼しない。
変更前の config を安全な場所に backup し、構文検査後に reload する。

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx
```

`nginx -t` が失敗した場合は reload しない。変更後は許可 network の管理者、非管理者、
許可外 network のそれぞれから `/admin` と確認した管理 API へのアクセスを試験する。
許可外から UI や管理操作に到達できる場合は公開しない。意図した login、JWKS、gRPC も
引き続き動作することを確認する。

## 3. 管理者を設定する

公開側の制限が整ったら、`/opt/lore/config/lore-auth.yaml` の `admin` section に
管理者の email を設定する。構築例にすでに設定済みの場合は重複させない。

```yaml
admin:
  admin_emails:
    - "<ADMIN_EMAIL>"
```

bridge 設定を変更した場合は、管理者と停止時間を調整し、設定を確認してから service を
再起動する。

```bash
sudo systemctl restart lore-auth
sudo systemctl is-active lore-auth
sudo journalctl -u lore-auth -n 100 --no-pager
```

管理 UI の管理者というだけでは repository 権限は付与されない。
`admin.global_repository_admin` を明示的に有効にすると、該当する有効な管理者に全有効
repository の read / write / admin が暗黙に付与され、DB grant は作られない。
対象は信頼できる管理者に限定し、設定変更後に server を再起動する。設定を戻しても
発行済み authz token は期限まで有効である。

設定後は [ログイン手順](001-login.md) に進む。
