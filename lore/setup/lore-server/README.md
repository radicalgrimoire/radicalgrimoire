# Lore Server 構築手順と前提条件

Ubuntu host に Lore Server を配置し、構築済みの `lore-auth-bridge` と接続する。
[`work/server-215.md`](../../work/server-215.md) を基に一般化した手順である。元の実機は
Ubuntu 26.04 LTS / x86_64 だが、この一般化した手順自体は別環境で通し検証していない。

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
設定例の port は `41337/tcp`・`41337/udp` と `41339/tcp`。利用者 network のみに公開する。
別 host に配置する場合は JWKS、certificate、systemd の依存関係を別途設計する。

`/datadrive` が意図した永続 storage として mount されていることを確認し、未確認なら中止する。

```bash
findmnt --mountpoint /datadrive
```

## 構築の順番

1. [Lore の build と配置](001-build.md)
2. [directory の作成](002-directories.md)
3. [Lore Server 設定](003-server-config.md)
4. [systemd と起動](004-systemd.md)
5. [server の受入確認](005-acceptance.md)
6. [Windows client の初回接続](006-windows-client.md)
7. [導入後の運用](007-post-deployment.md)
