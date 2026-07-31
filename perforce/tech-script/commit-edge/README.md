# P4 Server コミット/エッジ構成の補助スクリプト

コミット/エッジ構成を導入または変更する際の、読み取り専用の診断スクリプトです。設定の適用、サービスの起動停止、データ転送、`p4 trust`、`p4 login`、`p4 protect` は実行しません。

## スクリプト

| スクリプト | 実行場所 | 用途 |
| --- | --- | --- |
| `preflight.sh` | コミットまたはエッジの対象サーバー | `p4` / `p4d`、`P4ROOT`、`P4PORT`、任意の対向サーバーへの接続を確認する。 |
| `validate-edge.sh` | エッジへ接続できる端末 | エッジの `p4 info` と `p4 pull -lj` を確認する。 |

## 必要条件

* Bash 4 以降
* `p4` CLI。`preflight.sh` では `p4d` も必要
* 対象サーバーの情報を参照できる P4 ユーザーのログイン済みチケット
* `P4ROOT` を読める OS ユーザー。`preflight.sh` は対象サーバー上で実行する

パスワード、チケット文字列、秘密鍵を引数・環境変数・設定ファイルに渡さないでください。認証が必要なら、スクリプト実行前に対話的な `p4 login` を行います。

## 使用方法

### コミットサーバーの事前診断

```sh
export P4ROOT=/srv/perforce/commit/root
export P4PORT=ssl:commit.example.com:1666

bash preflight.sh --role commit
```

### エッジサーバーの事前診断

`--target` にはエッジから到達するコミットサーバーの `P4TARGET` と同じ値を渡します。

```sh
export P4ROOT=/srv/perforce/edge/root
export P4PORT=ssl:edge.example.com:1666

bash preflight.sh \
  --role edge \
  --target ssl:commit.example.com:1666
```

### 起動済みエッジの検証

```sh
bash validate-edge.sh \
  --p4port ssl:edge.example.com:1666 \
  --expected-server-id tokyo_edge
```

`p4 pull -lj` を実行する権限がない場合は、状態確認だけを省略できます。

```sh
bash validate-edge.sh \
  --p4port ssl:edge.example.com:1666 \
  --skip-pull-status
```

## 注意事項

* スクリプトの成功は、構成が本番運用可能であることを保証しません。`ExternalAddress`、`P4TARGET`、depot の実ファイル、バックアップ、クライアントからの sync / submit / shelve を別途確認してください。
* TLS のフィンガープリント確認は必ず人が行います。無条件の `p4 trust -y -f` は使いません。
* `security=4`、`p4 protect`、`p4 server -i` の適用は全体の認証・権限・データベースへ影響するため、自動化対象に含めません。
* `p4 pull -lj` はエッジへの接続・認証が必要です。失敗時はスクリプトを繰り返す前に P4LOG、`P4TRUST`、`P4TICKETS`、サービスユーザーを確認してください。
* 実行前に [コミット/エッジサーバー構成](../../administrator-manual/commit-edge-server-setup.md) を確認してください。