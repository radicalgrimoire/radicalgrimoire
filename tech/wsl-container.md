# WSL container (wslc) の導入と基本操作

WSL に同梱される `wslc.exe` を使い、Windows から Linux コンテナを実行する手順。
この構成のために Docker Desktop や Ubuntu 内の Docker Engine を別途インストールする必要はない。

確認日: 2026-10-26。必要バージョンとコマンドは末尾の Microsoft 公式資料に基づく。

## リリース状況

WSLc は **WSL 3.0.1 (2026-09-29 公開) で一般提供 (GA)** になった。
WSL 2.9.3 は機能が導入された Public Preview のバージョンであり、
公式資料の最低要件と、正式提供が始まったバージョンは異なる。
新規導入時は `wsl --update` で最新の安定版を使用する。

## 前提

- WSL が利用できる Windows 環境
- WSL バージョン **2.9.3 以上**
- コンテナイメージを取得するためのインターネット接続

以下のコマンドは Windows 側の PowerShell で実行する。

## 1. WSL をインストール・更新する

WSL が未導入の場合は、管理者 PowerShell でインストールする。
再起動を求められた場合は、再起動後に続行する。

```powershell
wsl --install
```

導入済みの場合も、更新してバージョンを確認する。

```powershell
wsl --update
wsl --version
```

確認するのは **WSL 自体のバージョン**であり、Ubuntu のバージョンや
ディストリビューションの WSL 1 / WSL 2 の区別ではない。

公式資料では WSL 2.9.3 以上が要件であり、プレリリース版への更新は必須ではない。
通常は `wsl --update` を使用する。

## 2. wslc の動作確認

```powershell
wslc version
wslc --help
wslc run --rm hello-world
```

初回はイメージが取得される。Hello メッセージが表示され、正常終了すれば動作確認完了。
`--rm` はコンテナ終了時にそのコンテナを自動削除する指定であり、イメージは残る。

Ubuntu イメージでコマンドを実行する場合:

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
```

## 3. Web サーバーを起動する

ホストのポート `8080` をコンテナのポート `80` へ転送し、nginx をバックグラウンドで起動する。
既にポート `8080` を使用している場合は、別のホスト側ポートを指定する。
コンテナ名 `web` も既存のコンテナと重複しないものにする。

```powershell
wslc run -d --rm -p 8080:80 --name web nginx
curl.exe http://localhost:8080
```

nginx の HTML が返ることを確認する。この例では Windows 自身からのアクセスを確認する。
他の PC からの公開範囲やファイアウォール設定は別途確認する。

稼働状態とコンテナ内の OS 情報を確認する。

```powershell
wslc container list
wslc exec web cat /etc/os-release
```

試用後は停止する。`--rm` を指定したため、停止するとコンテナも削除される。

```powershell
wslc container stop web
```

## 4. よく使う確認コマンド

```powershell
wslc image list
wslc container list --all
wslc stats
wslc run --help
```

`wslc` が見つからない場合は、まず `wsl --version` で要件を満たすか確認する。
更新後も見つからない場合は PowerShell を開き直し、次の結果とエラー内容を確認する。

```powershell
Get-Command wsl, wslc
wsl --version
```

## Docker Engine を使う構成との違い

- この資料は WSL 同梱の `wslc.exe` を直接使う手順。
- [WSL2 + Ubuntu + Docker Engine 構築メモ](wsl.md) は、Ubuntu 内に Docker Engine を導入する別構成。
- [Windows の Docker CLI 導入](docker.md) も別の手順であり、`wslc` の導入には不要。

CLI の見た目が似ていても、既存の Docker コンテナやイメージをそのまま共有する前提では扱わない。
Docker Compose を含む既存の Docker 運用を移行する場合は、必要な機能と互換性を個別に確認する。

## 参考資料

- [Microsoft Learn: WSL container](https://learn.microsoft.com/en-us/windows/wsl/wsl-container)
- [Microsoft Learn: Get started with containers on WSL](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)
- [Microsoft Learn: WSL container settings](https://learn.microsoft.com/en-us/windows/wsl/wsl-container-settings)
- [WSL リリース情報](https://github.com/microsoft/WSL/releases)
- [WSL 3.0.1: WSLc の一般提供](https://github.com/microsoft/WSL/releases/tag/3.0.1)
