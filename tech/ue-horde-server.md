# Unreal Horde Server の構築

Unreal Horde は、CI ジョブ、エージェント、成果物、ログを管理する Unreal Engine 向けのビルドオーケストレーション基盤です。Horde Server は MongoDB に状態を保存し、Redis をキャッシュとサーバー間通信に使用します。

## この構成の対象範囲

Epic は Linux 上の Docker コンテナで Horde を実行する方式を推奨しています。このリポジトリの `docker-compose.yml` は、その推奨方式を単一ホストで開始するために、Horde Server、MongoDB、Redis をまとめて起動する構成です。まずはこの構成を使用します。

利用規模、可用性、セキュリティ要件が高まった場合は、Docker を継続して利用しつつ、次を別途設計します。

* MongoDB と Redis のホストポートを外部公開しない、またはネットワークで接続元を制限する。
* HTTPS をリバースプロキシまたは Horde の Kestrel 設定で終端する。
* MongoDB、Redis、Horde の永続ボリュームをバックアップする。
* 複数の Horde Server を稼働させる場合は、全インスタンスから同じ MongoDB、Redis、ストレージへ接続する。

## 前提条件

Horde を実行する Linux ホストを用意します。Windows を利用する場合は、WSL2 上の Linux と Docker Engine を使う構成が扱いやすいです。

* Docker Engine と Docker Compose v2 がインストール済みであること。`docker compose version` で確認する。
* GitHub 上の Epic Games コンテナイメージを利用できるアカウント、またはこのリポジトリをビルドできる環境があること。
* Horde に接続する Perforce サーバーの接続先、ユーザー、認証情報が決まっていること。
* ホストの `13340/tcp` と `13342/tcp` を、Dashboard 利用者および Horde Agent から到達可能にすること。

Epic 提供イメージを直接 pull する場合は、Epic Games アカウントと連携済みの GitHub アカウントでパッケージ参照権限を取得し、PAT でログインします。PAT はシェル履歴や Compose ファイルへ保存しません。

```bash
docker login ghcr.io
docker pull ghcr.io/epicgames/horde-server:latest
```

対話入力を避ける場合は、`read -s` で PAT を一時的に変数へ読み込みます。公式パッケージへのアクセスには、`read:packages` 権限を持つ classic PAT が必要になる場合があります。トークンの権限要件は GitHub のパッケージ設定に従って確認します。

```bash
read -rsp 'GitHub PAT: ' CR_PAT; echo
printf '%s' "$CR_PAT" | docker login ghcr.io -u '<GitHub ユーザー名>' --password-stdin
unset CR_PAT
```

## リポジトリを取得する

```bash
git clone https://github.com/radicalgrimoire/horde-server.git
cd horde-server
```

このフォークには次の二つの起動方法があります。

| ファイル | 用途 |
| --- | --- |
| `default-docker-compose.yml` | Epic 提供の `ghcr.io/epicgames/horde-server:latest` を使用する構成 |
| `docker-compose.yml` | `horde/Dockerfile` で独自イメージをビルドする構成。Perforce CLI を追加する |

以降は `docker-compose.yml` を基準にします。Epic 提供イメージを使う場合は、`default-docker-compose.yml` を `docker-compose.yml` としてコピーするか、コマンドに `-f default-docker-compose.yml` を指定します。

## 起動前の設定

### 1. MongoDB の初期資格情報を変更する

`docker-compose.yml` に含まれる MongoDB の初期ユーザー名とパスワードはサンプル値です。必ず推測困難な値へ置き換え、同じ値を `Horde__DatabaseConnectionString` の接続文字列にも反映します。

```yaml
mongodb:
	environment:
		MONGO_INITDB_ROOT_USERNAME: <MongoDB 管理ユーザー>
		MONGO_INITDB_ROOT_PASSWORD: <MongoDB 管理パスワード>

horde-server:
	environment:
		Horde__DatabaseConnectionString: mongodb://<MongoDB 管理ユーザー>:<MongoDB 管理パスワード>@mongodb:27017/Horde?authSource=admin
```

パスワードに URL 予約文字を含める場合は、MongoDB 接続文字列内で URL エンコードが必要です。Compose ファイルをリポジトリへコミットしない運用では、`.env`、Docker secrets、またはデプロイ基盤のシークレット機能で値を注入します。

### 2. Perforce 接続設定を変更する

独自ビルド構成の `horde/Dockerfile` は `horde/.p4config` をイメージ内の `/root/.p4config` と `/app/.p4config` へコピーします。既定値の `localhost` とサンプル資格情報のままでは、コンテナからホスト上の Perforce へ接続できません。

ビルド前に `horde/.p4config` を環境に合う値へ変更します。

```ini
P4PORT=ssl:perforce.example.internal:1666
P4USER=horde-service
P4PASSWD=<サービスアカウントのチケットまたはパスワード>
```

`P4PASSWD` をイメージへ焼き込む方式は、資格情報のローテーションやイメージ共有に不向きです。Perforce のサービスアカウントには必要最小限の権限だけを付与します。

`horde/run.sh` の `p4 trust -y -f` は Perforce SSL 証明書を信頼する処理であり、`p4 login` によるログイン処理ではありません。再起動後の Perforce 認証をこのスクリプトへ追加して解決するのではなく、次節の Horde Server 設定で接続情報を管理します。`-y -f` は証明書のフィンガープリント検証を省略するため、運用環境では事前に証明書を検証して trust 情報を永続化する方式を検討します。

### 3. Horde に Perforce の接続情報を設定する

Horde Server 自身がストリーム設定や変更履歴を読むための Perforce 接続は、`server.json` の `Horde.plugins.build.perforce` に設定できます。`useLocalPerforceEnv` を `false` にして、コンテナ内の `.p4config` へ依存しない構成にします。`ticket` が指定されている場合は `password` より優先されます。

```json
{
	"Horde": {
		"Plugins": {
			"Build": {
				"UseLocalPerforceEnv": false,
				"Perforce": [
					{
						"Id": "main",
						"ServerAndPort": "ssl:perforce.example.internal:1666",
						"Credentials": {
							"UserName": "horde-service",
							"Ticket": "<有効期限を管理するログインチケット>"
						}
					}
				]
			}
		}
	}
}
```

チケットの有効期限は Perforce 側のポリシーに従います。期限切れを完全に避けるものではないため、サービスアカウント用チケットの発行・更新手順を運用化します。パスワードを設定する場合も、`server.json` へ平文で保存せず、Docker secret またはデプロイ基盤のシークレットから設定します。`p4` CLI をコンテナ内で手作業利用する必要がある場合は、`P4TRUST` と `P4TICKETS` の保存先を `/app/Data` 配下など永続ボリューム内に指定し、コンテナ再作成で消えないようにします。

### 4. 公開ポートを確認する

フォークの Compose 構成では、次のポートを使用します。

| ポート | プロトコル | 用途 |
| --- | --- | --- |
| `13340` | HTTP/1.1 | Dashboard と HTTP API |
| `13341` | HTTPS | Compose では公開定義のみ。証明書・`HttpsPort` 設定なしでは利用しない |
| `13342` | HTTP/2 | Horde Agent 向け gRPC |
| `27017` | MongoDB | 開発時の確認用。外部公開しない |
| `30002` | Redis | 開発時の確認用。外部公開しない |

インターネットに公開する場合、`13340` と `13342` を直接公開せず、TLS を設定したリバースプロキシ経由にします。Horde の `ServerUrl` は、利用者と Agent がアクセスする HTTPS の FQDN と一致させます。

## 起動と確認

起動前に Compose 定義を展開して確認します。機密値が画面や CI ログに出力される可能性があるため、共有ログへ保存しません。

```bash
docker compose config
```

初回はイメージの pull またはビルドを伴います。バックグラウンドで起動します。

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f horde-server
```

`horde-server`、`mongodb`、`redis` が起動済みになり、Horde Server のログに listen ポートとデータベース接続のエラーが出ていないことを確認します。その後、`http://<Horde ホスト名>:13340` をブラウザで開きます。Agent には HTTP/2 ポート `13342` へ到達できる URL を設定します。

フォークの Makefile を使う場合は、従来の `docker-compose` コマンドを前提としている点に注意します。Compose v2 環境では、上記の `docker compose` コマンドを直接使うのが確実です。

## 設定ファイルと永続データ

Compose は以下の名前付きボリュームを作成します。`docker compose down` は通常これらを削除しませんが、`docker compose down -v` はデータを削除するため復旧不能になります。

| ボリューム | 内容 |
| --- | --- |
| `mongodb` | Horde のジョブ、ユーザー、Agent などの永続状態 |
| `redis` | Redis の永続データ |
| `data` | Horde の `Data` ディレクトリ。初回起動後に `server.json` が生成される |
| `defaults` | Horde の既定設定 |
| `tools` | Horde が利用するツール |

Horde 固有のインフラ設定は `Data/server.json` に置きます。Docker 名前付きボリュームを使用する現行の `docker-compose.yml` では、直接ホストからこのファイルを編集できません。確認・編集には次を使用します。

```bash
docker compose exec horde-server sh
cat /app/Data/server.json
```

設定をホストの Git 管理下に置く場合は、Compose の `data` ボリュームをホストディレクトリの bind mount に変更します。`default-docker-compose.yml` は `./data:/app/Data` の例を含むため、その方式を参照できます。認証シークレットを含む `server.json` は公開リポジトリにコミットしません。

環境変数は ASP.NET の規則で設定できます。ネストしたキーは `__` で区切ります。

```yaml
environment:
	Horde__HttpPort: 13340
	Horde__Http2Port: 13342
	Horde__RedisConnectionConfig: redis:30002
	Horde__DatabaseConnectionString: mongodb://<user>:<password>@mongodb:27017/Horde?authSource=admin
```

公式ドキュメントとバージョンによって、MongoDB 接続設定名が `MongoConnectionString` として案内されることがあります。このフォークの Compose 定義で実際に設定されているキーは `Horde__DatabaseConnectionString` です。Horde イメージを更新した際は、同梱の `appsettings.json` と起動ログで設定名を再確認します。

## Tools と Horde Agent の配布

`/app/Tools` は、Dashboard から配布する Horde Agent などのバンドル済みツールの格納先です。Tools ボリュームを永続化するだけではダウンロード対象になりません。`server.json` の `Horde.plugins.tools.bundledTools` に、ツールの ID、バージョン、配置先、対象プラットフォームを登録します。

### Horde Agent 配布物を用意する

最初に、Horde Server と同じ Unreal Engine/Horde バージョンの公式配布物に Agent のバンドルが含まれているか確認します。コンテナを初回起動した後、Tools ボリュームを確認します。

```bash
docker compose exec horde-server sh -c 'find /app/Tools -maxdepth 3 -type f | head -50'
```

必要な Agent バンドルが存在する場合は、そのまま `bundledTools` に登録します。存在しない場合は、同じバージョンの Horde Server Windows MSI を検証用 Windows マシンへインストールし、`C:\Program Files\Epic Games\Horde\Server\Tools` の内容を取得します。MSI とコンテナイメージのバージョンが一致していることを確認してから、Horde ホストの永続 Tools 領域へコピーします。

```bash
# ホスト上で展開した配布物を、コンテナの永続ボリュームへコピーする例
docker compose cp ./HordeServerTools/. horde-server:/app/Tools/
docker compose exec horde-server find /app/Tools -maxdepth 3 -type f
```

公式設定リファレンスは、Tools のデータを `bundle create` で生成できることを記載していますが、配布済み Horde Agent からバンドルを生成する完全な手順までは公開していません。そのため、Docker コンテナ単体で Agent バンドルを取得・生成する手段は前提にしません。同一バージョンの Horde Server MSI または UE ソースの Horde ビルド成果物に含まれる Tools ディレクトリを、バンドル構造を保ったままコピーする運用が現実的です。ファイルを単純に zip 化せず、`BundledTools` の `Version`、`RefName`、`DataDir` をコピー元の構成と揃えます。Server または Agent を更新する際は、Tools 配布物も必ず同一バージョンへ更新します。

```json
{
	"Horde": {
		"Plugins": {
			"Tools": {
				"BundledTools": [
					{
						"Id": "HordeAgent",
						"Name": "Horde Agent",
						"Version": "<Horde Server と同じバージョン>",
						"RefName": "default",
						"DataDir": "/app/Tools/HordeAgent",
						"Platforms": ["win-x64"],
						"ShowInDashboard": true
					}
				]
			}
		}
	}
}
```

上記は設定項目の形を示す例です。`DataDir` の実際のディレクトリ構造と `Version`、`RefName` は、対象 Horde バージョンで生成したバンドルと一致させます。異なるバージョンの Windows MSI インストールから `Tools` ディレクトリをコピーする方法は動作検証用には使えますが、サーバーと Agent のバージョンを揃え、ライセンス・配布条件を確認してから使用します。

設定後、管理者が Dashboard の `Server > Agents` から `Download Agent` を利用できることを確認します。コマンドラインでの配布は次の形です。認証を有効にしたサーバーでは、管理者の `/account` ページから発行した Agent ソフトウェア用トークンを使用します。

```powershell
Invoke-WebRequest -Uri 'https://horde.example.internal/api/v1/agentsoftware/default/zip' -OutFile C:\Horde\HordeAgent.zip -Headers @{ Authorization = 'Bearer <ダウンロードトークン>' }
Expand-Archive -LiteralPath C:\Horde\HordeAgent.zip -DestinationPath C:\Horde -Force
```

ダウンロード済み Agent は `SetServer` で接続先を設定できます。

```powershell
dotnet C:\Horde\HordeAgent.dll SetServer -Name=Production -Url=https://horde.example.internal -Token=<登録トークン> -Default
```

## HTTPS と認証

本番環境では HTTPS を必須とします。Compose の `ports` に `13341:13341` を追加するだけでは TLS は有効になりません。`server.json` の `Horde` セクションで `httpsPort`、利用者が到達する URL で `dashboardUrl` と `serverUrl` を設定します。Horde 自身で TLS を終端する場合は、`Kestrel` の証明書設定も必要です。`HttpPort` と `Http2Port` を `0` にすれば、暗号化されていない通信を停止できます。

```json
{
	"Horde": {
		"HttpPort": 0,
		"HttpsPort": 13341,
		"Http2Port": 0,
		"DashboardUrl": "https://horde.example.internal:13341/",
		"ServerUrl": "https://horde.example.internal:13341/",
		"ServerPrivateCert": "/run/secrets/horde-agent.pfx"
	},
	"Kestrel": {
		"Certificates": {
			"Default": {
				"Path": "/run/secrets/horde-server.pfx",
				"Password": "<証明書パスワード>"
			}
		}
	}
}
```

`Kestrel.Certificates.Default` は Dashboard/API の HTTPS を提供する証明書です。`ServerPrivateCert` は Agent の SSL 通信で使用する PFX であり、自己署名証明書も使用できますが、その場合は Agent 側の `thumbprint` または `thumbprints` に信頼する拇印を設定します。両者の役割を混同せず、証明書ファイルとパスワードはイメージや Git に含めずシークレットとしてコンテナへ渡します。

リバースプロキシで TLS を終端する場合は、プロキシが HTTP/2/gRPC を正しく転送できることを確認したうえで、外部 URL を `DashboardUrl` と `ServerUrl` に設定します。組織の IdP を使う場合は、Horde の `AuthMethod: OpenIdConnect`、`OidcAuthority`、`OidcClientId`、`OidcClientSecret` を設定します。OIDC のリダイレクト URL と `ServerUrl` は外部公開 URL に揃えます。

OIDC は IdP 側のアプリ登録、リダイレクト URL、クレームと Horde ACL の対応、シークレット更新を設計する必要があります。このため、本書では HTTPS と設定キーの確認に留め、実際の導入手順は認証専用の別文書として管理します。小規模環境で外部 IdP を利用できない場合は、Horde 組み込みの `AuthMethod: Horde` も選択できますが、いずれの場合も HTTPS を先に有効化します。

## バックアップ、更新、停止

バックアップ対象は最優先で MongoDB、次に Horde の `data`、`defaults`、`tools` ボリュームです。Redis はキャッシュ用途が中心ですが、現行構成では永続化されるため、復旧方針を決めたうえで対象に含めます。ボリュームの場所を `docker volume inspect` で確認し、停止中または整合性を確保した状態でバックアップします。

```bash
docker compose stop
docker compose start

# コンテナとネットワークのみを削除する。名前付きボリュームは残る。
docker compose down
```

更新前には MongoDB と Horde データをバックアップし、検証環境で同じイメージタグと Compose 定義を試します。`latest` は内容が変化するため、本番では検証済みの固定タグまたはイメージ digest を指定します。更新後は `docker compose up -d --build`、ログ、Dashboard、Agent からのジョブ実行まで確認します。

## スケールさせる場合

複数台の Horde Server をロードバランサー配下に置く場合、各インスタンスが同一の MongoDB、Redis、アーティファクトストレージを利用する必要があります。公式の大規模構成では、軽量リクエストを扱う `Server` と、スケジュール処理を扱う `Worker` の RunMode を分離しています。単一 Compose 構成の `mongodb`、`redis`、ローカルボリュームを複数ホスト間で共有する方式にはしません。

## トラブルシューティング

| 症状 | 確認・対処 |
| --- | --- |
| Dashboard を開けない | `docker compose ps` で `horde-server` のポート公開を確認し、`docker compose logs horde-server` で起動例外を確認する。ホストのファイアウォールも確認する。 |
| MongoDB 接続に失敗する | MongoDB のユーザー名・パスワードと `Horde__DatabaseConnectionString` が一致しているか確認する。MongoDB のボリュームを既に初期化した後に初期化環境変数だけを変えても、既存ユーザーのパスワードは変わらない。 |
| Agent が接続できない | Agent から `13342/tcp` へ到達できるか、HTTP/2 を中継するプロキシ設定か、Horde が返す `ServerUrl` が外部 URL と一致するかを確認する。 |
| Perforce に接続できない | コンテナ内から `p4 info` を実行し、`P4PORT`、DNS、TLS 証明書、サービスアカウント権限を確認する。`localhost` はコンテナ自身を指す。 |
| 設定変更が反映されない | 編集した `server.json` が実際に `/app/Data/server.json` にマウントされているか確認し、コンテナを再作成してログで設定値を確認する。 |

## 参考文献

* [Horde Server - Unreal Engine Documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-server-for-unreal-engine)
* [Horde Deployment - Unreal Engine Documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-deployment-for-unreal-engine)
* [Horde settings - Unreal Engine Documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-settings-for-unreal-engine)
* [Horde authentication tutorial - Unreal Engine Documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-authentication-tutorial-for-unreal-engine)
* [Horde Agent - Unreal Engine Documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-agent-deployment-for-unreal-engine)
* [radicalgrimoire/horde-server](https://github.com/radicalgrimoire/horde-server)
* [Docker Compose in production](https://docs.docker.com/compose/how-tos/production/)
* [Docker CLI と Compose のインストール](docker.md)
* [WSL2 + Ubuntu + Docker Engine の構築](wsl.md)

Epic Games の公式コンテナパッケージは、GitHub アカウントと Epic Games アカウントの連携および Unreal Engine リポジトリへの閲覧権限が必要です。

* [Epic Games Horde Server container package](https://github.com/orgs/EpicGames/packages/container/package/horde-server)