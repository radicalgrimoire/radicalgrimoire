# lore-auth-bridge 構築手順

Ubuntu host に `lore-auth-bridge` と nginx を配置し、Microsoft Entra ID を接続する。
実機記録 [`work/lore-plaintext`](../../work/lore-plaintext/) を基に一般化した手順であり、
この手順自体は別環境で通し検証していない。以下は Lore Server と同一 host に配置する例。
実機の service user は `mgs`、配置先は `/datadrive/lore` である。
この手順では `lore` user と `/opt/lore` を使う一般化した例に置き換えており、
その構成を実機で検証したわけではない。使用する bridge revision の設定 schema と
Lore との互換性を確認する。
社内 IP / plaintext を基準とする。DNS / TLS では
[未検証の検討資料](../../work/lore-tls/README.md) と各手順の差分を確認する。

> [!WARNING]
> 新規構築用である。既存の DB、鍵、certificate、設定を初期化・上書きしない。
> client secret、JWT signing key、TLS private key、SQLite database を source control、
> chat、shell history に残さない。

## 0. 事前に決める値と構成

以下の `<...>` を実環境の値に置き換える。設定ファイル内の `<SERVER_HOST>` はシェル変数
ではないため、ファイルを作成するときに直接置き換える。

* `<SERVER_HOST>`
  * plaintext は社内 IPv4 address、TLS は DNS 名。URL、JWT、certificate SAN で一致させる。

* `<LISTEN_IP>`
  * nginx が待ち受ける server の社内 IPv4 address。DNS 名とは別に指定する。

* `<SERVER_IP>`
  * Lore Server から nginx へ接続するときの送信元 IPv4 address。ReBAC API の許可に使う。

* `<TENANT_ID>`
  * Entra tenant ID。

* `<CLIENT_ID>`
  * Entra application の client ID。

* `<ADMIN_EMAIL>`
  * bridge の初期管理者 email。

* `<BRIDGE_REVISION>`
  * Lore と互換性を確認した bridge の source revision、tag または commit。

以下の例では、service user を `lore`、binary と設定を `/opt/lore`、永続データを
`/datadrive/lore` に置く。異なる path を使う場合は、設定、systemd、permission のすべてを
整合させる。`/datadrive` はあらかじめ永続的な local block storage として mount する。
SQLite database は NFS、SMB、object storage に置かない。mount が利用できない状態で
ローカルの空 directory に store を作らないこと。

Lore の local store は immutable / mutable の双方を永続化する。

### この手順で使う配置先

service user は `lore`。以下は本手順の配置先であり、216 の実機とは異なる。

* **source / build**
  * 管理 user の `$HOME/src/lore-auth-bridge`

* **bridge / 管理 CLI**
  * `/opt/lore/bin/lore-auth-server`
  * `/opt/lore/bin/lore-authctl`

* **bridge 設定**
  * `/opt/lore/config/lore-auth.yaml`

* **証明書 / 秘密鍵**
  * `/opt/lore/certs/lore-server.crt`
  * `/opt/lore/certs/lore-server.key`

* **自己署名構成の trust bundle**
  * `/opt/lore/certs/lore-auth-trust-bundle.pem`

* **Entra client secret**
  * `/etc/lore/secrets/entra-client-secret`

* **SQLite database**
  * `/datadrive/lore/auth/data/lore-auth.sqlite3`

* **JWT signing key**
  * `/datadrive/lore/auth/keys`

* **nginx 設定**
  * `/etc/nginx/sites-available/lore-auth`

* **systemd unit**
  * `/etc/systemd/system/lore-auth.service`

DNS / TLS で CA 発行証明書を使う場合は、nginx が使う CA 証明書を
`/opt/lore/certs/lore-ca.crt` に配置し、bridge と Lore Server の trust 設定は
社内 CA と公開 CA を含む OS CA bundle を使う。

### 接続先

* **Lore client**
  * `lore://<SERVER_HOST>:41337` または `lores://<SERVER_HOST>:41337`。方式に応じて選択。

* **bridge HTTP、Entra callback、JWKS**
  * `https://<SERVER_HOST>:8080`

* **bridge gRPC**
  * `https://<SERVER_HOST>:8081`

* **nginx から bridge への内部接続**
  * `127.0.0.1:18080`
  * `127.0.0.1:18081`

`41337/tcp`・`41337/udp`、`8080/tcp`、`8081/tcp` を必要な利用者 network のみに制限する。
`41339/tcp` と bridge の内部 port は loopback に限定する。
DNS 名を使う場合は server と client の双方から名前解決できること。

## 認証基盤の構築順序

1〜9 は Lore Server を構築する前に行う。同一 host 構成の全体順序は
[セットアップの入口](../README.md#同一-host-での構築順序)を参照する。

1. [前提 package と build 環境](001-prerequisites.md)
2. [service user と directory](002-service-user.md)
3. [bridge の build・配置](003-build.md)
4. [TLS certificate の作成](004-tls.md)
5. [Entra application と client secret](005-entra.md)
6. [bridge 設定](006-configuration.md)
7. [nginx 設定](007-nginx.md)
8. [systemd と初期化](008-systemd.md)
9. [bridge の受入確認](009-acceptance.md)

## 次の段階と補足

- bridge の受入確認後、[Lore Server](../lore-server/README.md) を構築する。
- server の受入確認後、[管理者ユーザーを作成](010-admin-user-setup.md)する。
