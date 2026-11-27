# service user と directory

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

専用 user がなければ作成する。同名 user が既に存在する場合は、所有者や用途を確認してから
使用する。既存の directory を使う場合は、permission を変更する前に内容と影響を確認する。

```bash
sudo useradd --system --user-group --home-dir /nonexistent \
  --shell /usr/sbin/nologin lore
```

次を実行し、表示された mount と device が意図した永続 storage であることを確認する。
`/datadrive` 自体が mount point でない場合や、想定と違う場合は中止する。

```bash
findmnt --mountpoint /datadrive
```

確認後に directory を作成する。

```bash
sudo install -d -o root -g root -m 0755 \
  /opt/lore /opt/lore/bin
sudo install -d -o root -g lore -m 0750 \
  /opt/lore/config /opt/lore/certs \
  /etc/lore /etc/lore/secrets
sudo install -d -o lore -g lore -m 0750 \
  /datadrive/lore \
  /datadrive/lore/auth /datadrive/lore/auth/data /datadrive/lore/auth/keys
install -d -m 0755 "$HOME/src"
```

次は [bridge の build・配置](003-build.md)。
