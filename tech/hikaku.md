# LoreとPerforceの比較

このページでは、LoreとPerforce Helix Coreのワークフローやストレージモデルを比較します。どちらか一方を一律に優れていると評価するのではなく、機能と運用上の違いを整理します。Loreの内容はv0.10.0に基づき、Perforceの内容は以下に掲載した公式ドキュメントに基づきます。利用できる機能は、サーバーのバージョンや設定、導入形態によって異なる場合があります。

## 機能比較

| 項目 | Perforce Helix Core | Lore |
| --- | --- | --- |
| 運用モデル | 中央サーバーがdepotを管理し、作業領域を調整します。クライアントの作業領域は、depotのパスをローカルのパスに対応付けます。 | 中央のデプロイメントが正本となり、各ローカルリポジトリインスタンスが作業状態とコンテンツのキャッシュを保持します。 |
| オフライン作業 | 接続が切れていてもファイルを編集できます。再接続後に`p4 reconcile`を実行すると、サーバー外で追加・編集・削除したファイルを検出し、次のチェンジリストに登録します。depotの状態を必要とする操作にはサーバー接続が必要です。 | 編集、stage、commit、ブランチ作成、diffなどをオフラインで行えます。リモートへのsyncとpushには接続が必要です。 |
| ブランチ | 従来型のブランチに加えてStreamsを利用できます。Streamsではmainline、development、release、taskなどの階層と種類に応じて変更の流れを制御し、作業領域のビューを生成します。 | ブランチはリビジョングラフ上の第一級の名前です。ブランチは分岐点から始まり、マージは両方の親を持つリビジョンを作ります。Streamsのような所定の階層に従う必要はありません。 |
| 作業領域に取得する範囲 | クライアントビューでdepotのパスを作業領域に対応付け、取得対象に含めたり除外したりできます。Streamsにもsparse形式や生成ビューがあります。 | sparse viewでローカルに展開するパスを選び、それ以外は必要に応じて遅延取得します。大きなファイルはフラグメント単位で必要な部分を取得します。 |
| 大容量・バイナリファイル | 保存方法や扱いはファイル種別で決まります。通常、バイナリのリビジョンは全体を保存し、テキストのリビジョンは差分として保存します。ファイル種別や修飾子で設定を変更できます。 | コンテンツをバイト列として扱います。大きなファイルはフラグメントに分割され、コンテンツアドレス方式により、同一リポジトリ内のファイル間で一致するフラグメントを重複保存しません。 |
| 排他的な編集 | `p4 lock`でファイルをロックすると、ロックが解除されるかロックしたユーザーがsubmitするまで、他のユーザーはそのファイルの変更をsubmitできません。 | `lore lock acquire`、`status`、`release`でサーバー上のロックを調整できます。v0.10.0ではロックの利用は任意で、すべてのpushに対してサーバーがロック取得を必須にするものではありません。より強い強制機構については[ロックの提案](../proposals/2026-06-19-successor-locks-unmergeable-files.md)を参照してください。 |
| 古いファイルデータのアーカイブ | 管理者は`p4 archive`で対象となるファイルリビジョンをarchive depotへ移し、`p4 restore`で戻せます。復元するまで通常のコンテンツ読み取りコマンドからは利用できませんが、リビジョンのメタデータは参照できます。 | AWSバックエンドはフラグメントをS3オブジェクトとして保存し、Loreの設計ではストレージ階層化をデプロイメント側の責務として説明しています。ただし、`p4 archive`／`p4 restore`のようにリビジョン単位でアーカイブ・復元するユーザー向けの操作はありません。`lore branch archive`はブランチ名の対応付けをアーカイブするもので、フラグメントを低温ストレージへ移す機能ではありません。 |
| アクセス境界 | protections tableでdepotのパスごとにアクセスを許可できます。 | リポジトリはストレージのpartitionであり、アクセス境界です。リンクした別リポジトリで、より細かい境界を作れます。ただし、単一リポジトリ内の任意のパスにACLを設定する方式とは異なります。 |
| 実装とフォーマット | 専用サーバーとプロトコルを持つ、成熟した商用製品です。 | MITライセンスで、データ形式とワイヤプロトコルは公開仕様としてバージョン管理されています。 |

## 選び方

既存のスタジオ向けワークフロー、Streamsのポリシー、排他的なファイルロック、管理者によるarchive depot運用を活用するチームには、Perforceが自然な選択肢です。サーバーを中心に操作を調整する運用が標準であることも利点になります。

オフラインでのローカルなリビジョン作業、大規模リポジトリへのsparse／遅延アクセス、バイナリ中心のコンテンツに対するフラグメント単位の重複排除、公開された実装と仕様を重視するチームは、Loreの設計対象に近いでしょう。ただし、Loreのロックやアーカイブ機能が、Perforceの強制力やarchive depotの挙動と同等だとは限りません。

用語や概念は一対一には対応しません。PerforceのチェンジリストやStreamsを、Loreのリビジョンやブランチにそのまま置き換えることはできません。移行を検討する場合は、コマンド名の対応付けだけでなく、実際のブランチ運用、ロック、ビルド、データ保持の流れを検証してください。

## Perforceの参考資料

- [P4 reconcile](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_reconcile.html) — オフライン作業を含め、サーバー外で発生した作業領域の変更を検出します。
- [P4 lock](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_lock.html) — 開かれたファイルに対するサーバー側ロックを説明しています。
- [P4 stream](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_stream.html) — Streamの種類、階層、変更フローのポリシーを説明しています。
- [P4 client](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_client.html) — 作業領域のビューとStreamに関連付けたクライアントを説明しています。
- [ファイルの保存形式](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/P4Guide/filetypes.storage.html) — バイナリリビジョンの全体保存、テキストリビジョンの差分保存という標準動作を説明しています。
- [P4 archive](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_archive.html)と[P4 restore](https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_restore.html) — リビジョンをarchive depotへ移動し、戻す方法を説明しています。

## 関連ドキュメント

- [システム設計](system-design.md) — Loreのアーキテクチャと設計目標。
- [Lore CLIコマンドリファレンス](../reference/lore-cli-commands.md) — Loreコマンドの詳細。
- [リリースノート](../release-notes.md) — Lore各バージョンの変更内容。
