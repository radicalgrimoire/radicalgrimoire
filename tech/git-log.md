# 貴方へ

もし貴方が何かに不満を持って実行を試みたい場合は一度踏みとどまるべきですが、
どうしようもない感情に襲われ、何かに際悩み、苦しんでいるとき。実行してしまいましょう。
全てがすっきりすることで何か心のモヤモヤが晴れるかもしれません

## 実行前の確認

* 共同作業者がいる場合は、作業前に共有する。
* 念のため現在の状態を別の場所へ clone またはバックアップする。
* 保護ブランチでは強制 push が拒否されるため、必要なら一時的にルールを確認する。

```bash
git status
git branch --show-current
git remote -v
```

以下では、既定ブランチが `main` であるものとする。異なる場合は読み替える。

## 履歴を作り直す

`--orphan` で親コミットを持たない新しいブランチを作成する。作業ツリーのファイルはそのまま残る。

```bash
git switch --orphan fresh-main
git add -A
git commit -m "Initial commit"
```

この時点では、`fresh-main` に新しい 1 コミットだけが存在する。内容を確認する。

```bash
git log --oneline
git status
```

問題なければ、既存の `main` を新しい履歴で置き換える。

```bash
git branch -D main
git branch -m main
git push --force origin main
```

GitHub などで既定ブランチを `main` にしている場合は、リモート側でもコミット履歴が 1 件になったことを確認する。

## 共同作業者の対応

古い履歴を持つ clone では、そのまま pull せずに clone し直すのが確実。

```bash
git clone <repository-url>
```

既存ディレクトリを使い続ける必要がある場合は、未コミットの変更を退避したうえで、リモートの新しい履歴に合わせる。

```bash
git fetch origin
git switch main
git reset --hard origin/main
```

## 補足

リモートに古いコミットがしばらく残ることや、fork に履歴が残ることがある。秘密情報を含めてしまった場合は、履歴の書き換えとは別にトークン、パスワード、鍵を無効化して再発行する。

