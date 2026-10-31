# lore-auth-bridge 構築手順

Ubuntu host に `lore-auth-bridge` と nginx を配置し、Microsoft Entra ID を接続する。
実機記録 [`work/server-215.md`](../../work/server-215.md) を基に一般化した手順であり、
この手順自体は別環境で通し検証していない。以下は Lore Server と同一 host に配置する例。
使用する bridge revision の設定 schema と Lore との互換性を確認する。

> [!WARNING]
> 新規構築用である。既存の DB、鍵、certificate、設定を初期化・上書きしない。
> client secret、JWT signing key、TLS private key、SQLite database を source control、
> chat、shell history に残さない。

## 0. 事前に決める値と構成

以下の `<...>` を実環境の値に置き換える。設定ファイル内の `<SERVER_HOST>` はシェル変数
ではないため、ファイルを作成するときに直接置き換える。

| 値 | 用途 |
| --- | --- |
| `<SERVER_HOST>` | client から接続できる server の DNS 名または IPv4 address。URL、JWT、certificate SAN で一致させる |
| `<SERVER_IP>` | Lore Server から nginx へ接続するときの送信元 IPv4 address。ReBAC API の許可に使う |
| `<TENANT_ID>` | Entra tenant ID |
| `<CLIENT_ID>` | Entra application の client ID |
| `<ALLOWED_EMAIL_DOMAIN>` | 対象の email domain |
| `<ADMIN_EMAIL>` | bridge の初期管理者 email |
| `<BRIDGE_REVISION>` | Lore と互換性を確認した bridge の source revision、tag または commit |

以下の例では、service user を `lore`、binary と設定を `/opt/lore`、永続データを
`/datadrive/lore` に置く。異なる path を使う場合は、設定、systemd、permission のすべてを
整合させる。`/datadrive` はあらかじめ永続的な local block storage として mount する。
SQLite database は NFS、SMB、object storage に置かない。mount が利用できない状態で
ローカルの空 directory に store を作らないこと。

bridge、Lore Server、reverse proxy は別 host に分けることもできる。その場合は network
boundary、永続化と recovery の責任分界を別途設計する。Lore の local store は immutable /
mutable の双方を永続化する。cloud backend は使用 binary の対応を確認し、clone / pull の
転送量と egress cost も評価する。Lore の AWS 例は S3 単独ではなく S3 と DynamoDB を使う。

| 接続先 | 用途 |
| --- | --- |
| `lore://<SERVER_HOST>:41337` | Lore client |
| `https://<SERVER_HOST>:8080` | bridge HTTP、Entra callback、JWKS |
| `https://<SERVER_HOST>:8081` | bridge gRPC |
| `127.0.0.1:18080` / `127.0.0.1:18081` | nginx から bridge への内部接続 |

`41337/tcp`・`41337/udp`、`41339/tcp`、`8080/tcp`、`8081/tcp` を network boundary で
許可し、利用者の network だけに制限する。bridge の内部 port は外部に公開しない。
DNS 名を使う場合は server と client の双方から名前解決できること。

## 構築の順番

1. [前提 package と build 環境](001-prerequisites.md)
2. [service user と directory](002-service-user.md)
3. [bridge の build・配置](003-build.md)
4. [TLS certificate の作成](004-tls.md)
5. [Entra application と client secret](005-entra.md)
6. [bridge 設定](006-configuration.md)
7. [nginx 設定](007-nginx.md)
8. [systemd と初期化](008-systemd.md)
9. [bridge の受入確認](009-acceptance.md)
10. [利用者登録と repository へのアクセス](010-user-onboarding.md)
11. [導入後](011-post-deployment.md)

関連資料: [Identity Provider と招待](012-identity-providers.md)。
