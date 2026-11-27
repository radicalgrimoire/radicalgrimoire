# Loreの新機能

大きなリポジトリでの作業では、ファイルの取得待ちや、作業環境を増やすたびに必要になる
ディスク容量が負担になる。Loreには、必要な内容を使うときに取得し、
取得済みのデータを再利用しながら作業環境を増やす機能がある。

## お品書き

- Linuxの仮想クローン
- アクセス記録による先読み
- sync時の構成情報の一括取得
- Copy-on-Writeによる作業環境の複製
- オフラインでのcommit
- Bazelのリモートビルド

## Linuxの仮想クローン

**Google Driveのストリーミングのように、ファイル名は見えていて、中身は必要になったときに取得する。**
これがLoreの仮想クローンである。

Linuxで次のコマンドを実行すると、`my-project` に仮想クローンが作られる。
URLは接続先のLore Serverとリポジトリに合わせて置き換える。

```bash
lore clone lore://example.invalid:41337/my-project my-project --vfs fuse
```

作業フォルダはエディタから普通に開ける。まだ手元にないファイルを読むと、
Loreがサーバーから必要な内容を取得する。取得済みの内容はマシン上の共有storeから再利用する。
最初からすべてのファイルをダウンロードしなくてよいため、大きなリポジトリの一部を使う作業に向いている。

ファイルを編集した後は `lore status` で変更を確認し、`lore stage` と `lore commit` で
履歴に記録できる。保存しただけでは自動的にcommitやpushはされない。
`sync`、`reset`、`merge` にも対応する。

エディタの索引作成やビルドでも、ファイルを読めば取得が発生する。
未取得のファイルを読むときは通信待ちが発生する場合があり、
多くのファイルを使う作業では、その分の取得が必要になる。

## アクセス記録による先読み

オンデマンド取得では、初めてファイルを読む時点に取得待ちが発生する。
今回の更新には、その待ちを減らすための入力としてアクセス記録を使う仕組みがある。

流れは次のとおり。

1. Lore serviceの環境に `LORE_FUSE_RECORD_DIR` を設定し、FUSE上のアクセスを記録する。
2. エディタの起動やビルドなど、対象にしたい作業を実行する。
3. その記録ファイルを、次の `lore clone --vfs fuse --prefetch <file>` に渡す。
4. 記録を基に共有storeをウォームアップする。

cloneが戻った後のバックグラウンド処理で、記録されたディレクトリの情報とファイル内容を取得する。
cloneの完了を、先読みの完了や全入力の取得済みという意味で扱わない。

この機能では、実際の作業で得たアクセス記録を再利用する。
どのファイルが必要かを手で列挙する代わりに、代表的な作業で読まれた対象を入力にできる。

記録は、その実行でアクセスした対象であって、依存関係を完全に列挙したものではない。
別のビルド設定、テスト、編集対象では追加の取得が発生し得る。

## sync時の構成情報の一括取得

v0.13.0から、instanceの `.lore/config.toml` に次の設定を追加すると、
`lore sync` の対象revisionのファイル・フォルダの構成情報をまとめて取得する。

```toml
[sync]
prefetch_tree = true
```

上で紹介したファイル内容の先読みとは別の機能で、既定では無効になっている。
viewで対象を絞っていても構成情報は全体を取得するため、
大きなリポジトリの大部分をsyncする場合に検討する。

## Copy-on-Writeによる作業環境の複製

Loreのrepository instanceは、独立した作業ツリー、view、stage状態を持つローカル作業環境である。
複数のinstanceは同じ共有storeを使い、取得済みのfragmentを再利用できる。

ここでは、次の二つの共有を区別する。

| 共有するもの | 意味 |
| --- | --- |
| 共有storeの内容 | instance間で、取得・保存したfragmentを再利用する |
| 作業ツリーのデータブロック | 複製元と複製先のファイルが、ファイルシステム上の物理ブロックを共有する |

共有storeを使うだけで、通常ファイルとして展開した作業ツリーまで自動的にブロック共有されるわけではない。
`lore repository instance clone` は、後者も扱う機能である。
共有store上のinstanceを複製し、APFS、Btrfs、XFS、ReFS、Dev Driveでデータブロックを共有する。

Copy-on-Writeでは、共有部分をそのまま参照し、書き換えに応じて別の領域を使う。
追加の作業環境を作るたびに、最初から全内容の独立したコピーを持つ方式とは容量の増え方が異なる。
ただしメタデータ、変更内容、新しく生成されるビルド成果物の容量までゼロにはならない。
利用するボリュームの機能・設定と、対象buildの制約を確認する必要がある。

レビュー用、修正用、ビルド用の作業環境を同じマシンに並べる用途に活用できる。
同じディスクやstoreに依存するため、独立したバックアップの代わりにはしない。

## オフラインでのcommit

v0.11.0から、`lore clone --offline` または `--cache` で準備した作業環境では、
サーバーに接続していなくても `stage` と `commit` ができる。

```bash
lore clone lore://example.invalid:41337/my-project my-project --offline
```

clone自体にはサーバーへの接続が必要で、必要なデータを取得できなければ失敗する。
オフラインで記録したrevisionは、接続できるようになってから `lore push` で共有する。
仮想クローンの未取得ファイルをオフラインで読めるという意味ではない。

## Bazelのリモートビルド

v0.11.0には、Bazelのリモートビルド向けの `contrib/bazel/` が含まれる。
別マシンのworkerでビルドを実行し、入力や成果物、ビルド結果のキャッシュをLoreのstoreで共有する。

Bazel Remote Execution API v2に対応する、独立して構築・運用するサーバーである。
通常のLore Serverを起動するだけで自動的に動く機能ではない。

## 参考資料

- [Linuxの仮想クローン](https://github.com/radicalgrimoire/lore/blob/73a455d6a957004fdef2a9b3953cc9002263ca28/docs/how-to/use-virtual-clones-on-linux.md)
- [FUSEとアクセス記録のリリースノート](https://github.com/radicalgrimoire/lore/blob/73a455d6a957004fdef2a9b3953cc9002263ca28/docs/release-notes/virtual-clones-on-linux.md)
- [共有store上の並行instance](https://github.com/radicalgrimoire/lore/blob/73a455d6a957004fdef2a9b3953cc9002263ca28/docs/how-to/run-parallel-instances-over-a-shared-store.md)
- [Bazel向けリモートビルドサーバー](https://github.com/radicalgrimoire/lore/blob/73a455d6a957004fdef2a9b3953cc9002263ca28/contrib/bazel/README.md)

基本的な利用手順は[CLIの基本操作](001-cli-usage.md)、
更新作業は[Lore Serverの更新](../operations/004-upgrade.md)を参照する。
