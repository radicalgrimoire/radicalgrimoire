# IdP を使わないローカル検証

外部 IdP を使わず、bridge、Lore Server、CLI の経路を検証するための流れ。
bridge `b332e35` の旧 quickstart を基に整理したもので、以下の一般化された手順は
通し検証していない。本番の Entra login、proxy 境界、実環境の権限を確認したことにはならない。

## 前提と準備

互換性を確認した `lore`、`loreserver`、`lore-auth-server`、`lore-authctl` を用意し、
それぞれの revision と `--help` を確認する。既存 DB、鍵、store を初期化・削除しないよう、
隔離された新しい作業 directory と未使用 port を使う。token と秘密鍵の permission を制限する。

1. bridge gRPC 用の TLS certificate を作成し、CLI と Lore Server に正しい trust anchor を
   渡す。mkcert は leaf ではなく root CA、自己署名 certificate は対象 revision での
   trust 方法を確認する。接続名と SAN を一致させる。
2. bridge の HTTP / gRPC listener、SQLite path、JWT issuer / audience、鍵 directory、
   `active_kid`、Lore remote と auth URL を設定する。Lore Server の issuer / audience、
   HTTP JWKS、gRPC auth URL、local store と揃える。配布形態によっては `default.toml` が必要。
3. 対象 revision の `--help` で command を確認して新しい DB を初期化し、active key を生成する。
   管理 CLI で manual user を作成し、authn token を制限された file に発行する。
   [token 発行](../operations/token-flows.md#管理-cli-による発行)を参照する。

## 接続確認

1. bridge を起動し、HTTP health と JWKS を確認する。次に TLS trust を設定した Lore Server
   を起動する。HTTP health の成功は gRPC の成功を意味しない。
2. CLI に authn token を登録し、検証専用 repository を作成する。bridge の `repo list` で
   ReBAC 同期を確認する。
3. その user に最小の writer grant を付与し、`check` で write の `allow` を確認する。
   続けて未使用の directory に clone し、必要なら検証専用 repository で write を確認する。
4. 失敗時は endpoint、証明書と trust、issuer / audience、grant、server / bridge log を
   確認する。login だけの成功では token exchange や ReBAC を確認できない。

コマンド例を含む元の [quickstart（固定 revision）](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/hands-on-quickstart.md)
は古い binary や port を前提とする。実行前に現在の help、既存データ、各コマンドの影響を確認する。
