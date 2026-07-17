
# LOREに関する簡易まとめ

- https://epicgames.github.io/lore/
- https://github.com/EpicGames/lore

# インスコ

> curl -fsSL https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.sh | bash -s -- --install-dir {install folder}--server

```
[Unit]
Description=Lore Server
After=network.target

[Service]
Type=simple
User=user
Group=user
Environment=RUST_LOG=info
Environment=LORE_ENV=dev
Environment=LORE_CONFIG_PATH=/datadrive2/lore/config
ExecStart=/datadrive2/lore/bin/loreserver
WorkingDirectory=/datadrive2/lore
LimitNOFILE=1048576
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```


# LORE CLI

> # PowerShellで実行
> irm https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.ps1 | iex
>
> ここでは CLI からの操作を中心にまとめる。Linux サーバー側の構築例は別途、コンテナ構築をベースに簡潔に記載する。

## 起動チェック

> ex)
> curl -i http://127.0.0.1:41339/health_check

127.0.0.1は、LOREサーバーのアドレスに適宜変更。ここでは 41339 を HTTP ヘルスチェック用、リポジトリ操作は 41337 の lore:// エンドポイントを使う。

## リポジトリ作成

### test という名称のリポジトリを作成する

> PS D:\> lore repository create lore://127.0.0.1:41337/test  
> Created repository test in D:/ with ID 019ef76f0d027753b1af0286c57cde4e

### リポジトリ確認

> PS D:\> lore repository list lore://127.0.0.1:41337

### リポジトリの情報確認

> PS D:\> lore repository info lore://127.0.0.1:41337/test
> test (019ef76f0d027753b1af0286c57cde4e)
>
> Remote URL: lore://127.0.0.1:41337
> Default branch: main (e726318bbc3fd75ac8733a7e030cc35b)
> Creator: <unknown>
> Created: Wed, 21 Jan 1970 15:04:27 +0000

### test という名前のリポジトリをcloneする

> lore clone lore://127.0.0.1:41337/test --identity ueno.s@gamestudio.co.jp

### ファイルを追加する（編集）

> PS D:\aaa\test> lore stage ./test.txt
> Staging file system changes
> Staging 1 files (0 modified, 1 added, 0 deleted, 0 moved)
> Staged repository state 0f62b20e473e4b28bfcfdd14dd2f084e745bf29e296fb9faa3fa4c3d07361c04

追加、編集、削除、ファイル移動も一括でstageコマンド

### コミットする

> PS D:\aaa\test> lore commit "add"
Fragmenting files and updating tree hashes
Committing staged changes
Committed 0/0 directories, 1/1 files (0 modified, 1 added, 0 deleted)
Stored history for 1 nodes
Repository: 019ef36d0d6a747394e88951e89e8b33
Revision  : 2
Signature : d7626851eabb693bb8a3626e4b7512d4a29a02d881da16285d4d606776bdf464
Parent    : 1ed9583a3af51270d209ffc80f057cd33f69b728f42d296fd9764ebfc0b8dadd
Branch    : e726318bbc3fd75ac8733a7e030cc35b
Date      : Wed, 24 Jun 2026 02:28:27 +0000
    add
Creator   : ueno.s@gamestudio.co.jp
Committer : ueno.s@gamestudio.co.jp
Commit succeeded

# push する

> PS D:\aaa\test> lore push
Local branch is 1 revision(s) ahead of remote, pushing all revisions
Repository 019ef36d0d6a747394e88951e89e8b33
Pushing 1 fragment(s)
Pushed 1 fragment(s), 148.00 bytes
Pushing d7626851eabb693bb8a3626e4b7512d4a29a02d881da16285d4d606776bdf464 to branch main
Pushed revision 2 -> d7626851eabb693bb8a3626e4b7512d4a29a02d881da16285d4d606776bdf464 to branch main
