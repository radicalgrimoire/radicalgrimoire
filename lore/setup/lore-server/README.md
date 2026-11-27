# Lore Server 構築手順と前提条件

Ubuntu host に Lore Server を配置し、構築済みの `lore-auth-bridge` と接続する。
[`work/lore-plaintext`](../../work/lore-plaintext/) を基に一般化した手順である。元の実機は
Ubuntu 26.04 LTS / x86_64 だが、この一般化した手順自体は別環境で通し検証していない。
DNS / TLS は [未検証の検討資料](../../work/lore-tls/README.md) を参照する。

> [!WARNING]
> 新規構築用である。既存の store、設定、certificate を初期化・上書きしない。

## 前提条件

先に [lore-auth-bridge 構築手順](../lore-auth-bridge/README.md) の
[受入確認](../lore-auth-bridge/009-acceptance.md) までを実施し、
bridge と nginx が同じ host で稼働し、health / JWKS が正常であることを確認する。
その手順で作成する service user `lore`、`/opt/lore`、`/datadrive/lore`、
certificate と Rust toolchain を利用する。

以下の `<SERVER_HOST>` は bridge 側と同じ DNS 名または IPv4 address、
`<LORE_REVISION>` は使用する bridge と互換性を確認した Lore revision に置き換える。
設定例では `41337/tcp`・`41337/udp` を必要な利用者 network に制限し、
`41339/tcp` は loopback に限定する。
別 host に配置する場合は JWKS、certificate、systemd の依存関係を別途設計する。

`/datadrive` が意図した永続 storage として mount されていることを確認し、未確認なら中止する。

```bash
findmnt --mountpoint /datadrive
```

### この手順で使う配置先

以下は配置例である。
利用するサーバー環境に合わせて、配置先、設定、systemd、権限を変更する。

* **source / build**
  * 管理 user の `$HOME/src/lore`

* **Lore Server / CLI**
  * `/opt/lore/bin/loreserver`
  * `/opt/lore/bin/lore`

* **server 設定**
  * `/opt/lore/config/lore-server/production.toml`

* **証明書 / 秘密鍵**
  * `/opt/lore/certs/lore-server.crt`
  * `/opt/lore/certs/lore-server.key`

* **immutable / mutable store**
  * `/datadrive/lore/store`

* **systemd unit**
  * `/etc/systemd/system/loreserver.service`

証明書と秘密鍵は bridge の手順で準備したものを共用する。

## 構築の順番

1. [Lore の build と配置](001-build.md)
2. [directory の作成](002-directories.md)
3. [Lore Server 設定](003-server-config.md)
4. [systemd と起動](004-systemd.md)
5. [server の受入確認](005-acceptance.md)

server の単体確認後は [管理者ユーザーの作成](../lore-auth-bridge/010-admin-user-setup.md)、
[Windows CLI のインストール](../windows-cli-setup.md)の順に進む。
全体の順序と導入後の確認は[セットアップの入口](../README.md)を参照する。
