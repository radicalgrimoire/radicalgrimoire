# LORE 試用ガイド

社内テスト用 Lore Server で、ファイルの追加、commit、push を試すための短い手順である。
本番プロジェクトや業務データは使用しない。

## 事前準備

管理者に、会社メールアドレスで `lore-test` repository への `writer` 権限を依頼する。
権限付与後に、この手順を進める。

## 1. Lore CLI をインストールする

Windows PowerShell を開き、次を実行する。

```powershell
irm https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.ps1 | iex
lore --version
```

`lore` が見つからない場合は、PowerShell を開き直してから再実行する。

## 2. ログインする

```powershell
lore auth login lore://172.20.12.193:41337
```

ブラウザーが開いたら、会社の Entra ID アカウントでログインする。

ログイン後、利用できるrepositoryに `lore-test` が表示されることを確認する。

```powershell
lore repository list lore://172.20.12.193:41337 --remote --no-pager
```

`lore-test` が表示されない、または後続のcloneが権限エラーになる場合は、管理者に
writer 権限を依頼する。

## 3. 試験用repositoryをcloneする

以下では `D:\LoreTryout` を使用する。既に同名のdirectoryがある場合は、別の空の
directoryを指定する。

```powershell
lore repository clone `
  lore://172.20.12.193:41337/lore-test `
  D:\LoreTryout

cd D:\LoreTryout
lore repository status
```

## 4. ファイルを追加してcommitする

自分専用のファイルを追加する。`$env:USERNAME` がファイル名に入るため、他の試用者と
衝突しにくい。

```powershell
$file = "hello-$env:USERNAME.txt"
Set-Content -LiteralPath $file -Value "Hello from $env:USERNAME"

lore stage $file
lore commit "Add trial file for $env:USERNAME"
lore push
```

`lore commit` はローカルのrevisionを作成し、`lore push` がサーバーへ送信する。
両方が成功したことを確認する。

## 5. 更新履歴を確認する

```powershell
lore revision history --oneline 10
```

他の人の試用commitも含め、最新のrevisionが表示されれば完了である。

## 困った場合

* **ログインできない**: 会社のEntra IDアカウントを使っているか確認し、再度
  `lore auth login lore://172.20.12.193:41337` を実行する。
* **`lore-test` が見えない／権限エラーになる**: 管理者に会社メールアドレスとともに
  `lore-test` の writer 権限を依頼する。
* **pushが失敗する**: `lore repository status` とエラー全文を管理者へ送る。自分で
  repositoryを作り直したり、他の人のファイルを削除したりしない。

試用後にローカルの作業directoryが不要になれば、`D:\LoreTryout` を削除してよい。
削除するのは自分のローカルdirectoryだけであり、Lore Server 上の `lore-test` は削除
しない。

詳細なCLI操作は [LORE CLI の利用](./cli.md)、管理者向けのアカウント・権限設定は
[LORE Server のアカウント管理](../work/server-193-account.md) を参照する。
