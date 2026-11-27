# Lore と lore-auth-bridge の認証境界

2026-10-31 時点の構築方針メモ。

- Lore Server は認証設定なしでも動作する。その場合、接続できる利用者は認証なしで
  repository を作成・利用でき、利用者ごとの権限制御は行われない。
- Lore Server を lore-auth-bridge と連携するよう設定すると、repository 操作に
  token が必要になる。bridge 側で user / group ごとの repository 権限を管理し、
  新規 repository の作成は bridge の管理者に限定する。
- bridge を起動しただけでは Lore Server の認証は有効にならない。両者の連携設定と
  TLS を含め、実際に認証なしの操作が拒否されることを確認する。
- Entra ID の信頼済みデバイスや接続元 IP などの条件付きアクセスは、運用環境の
  Entra ID 側で設定する。bridge の管理画面は管理者アカウントに限定されるが、
  管理画面への IP 制限は別途 bridge または reverse proxy で設定する。
- bridge の group CIDR 制限は現在、すべての token 発行経路には適用されない。
  browser の token 発行と device flow を含む適用範囲の整理は
  [Issue #5](https://github.com/radicalgrimoire/radicalgrimoire/issues/5) の残課題。
  既に発行された token も、CIDR の変更だけでは失効しない。

Entra ID の条件付きアクセス、ネットワーク制限、証明書の信頼、保存先と backup は
構築環境ごとに確認する。このメモは各環境の設定済み状態や安全性を保証するものではない。

## Jenkins と service account の運用

service account の login では Client ID / Client Secret と接続元 IP を確認する。
所属 group に許可 CIDR がない場合や接続元 IP が一致しない場合は拒否される。
Entra ID の信頼済みデバイス判定は、この service account の login には適用されない。
管理画面と現行 source の CLI は、新規 service account の作成時に既存 group を必須とする。
既存の未所属 account は変更されず、作成後の所属解除も制限されない。実環境に適用済みかは
各 server の binary version を確認する。

Client Secret は Jenkins が保管する credential の確認には使えるが、コピーして
別の場所から使うこともできるため、Jenkins 自身や特定の job・runner の証明にはならない。
許可 IP を共有する端末も区別できず、IP 判定は reverse proxy の設定にも依存する。
CIDR の変更や Secret の rotation は、既に発行された token を失効させない。

信頼できる社内 Jenkins と runner を前提に利用する場合は、次の運用でリスクを抑える。

- Secret を Jenkins の credential 管理に保管し、ログや設定ファイルに露出させない。
- credential を利用できる job、管理者、runner を必要な範囲に絞る。
- group の許可 CIDR を、job が実行される runner の実際の送信元 IP に絞る。
- service account の repository 権限を必要最小限にし、漏えい時は Secret を rotation する。

これは Jenkins や runner 自体の侵害に耐える保証ではない。利用範囲が広がり、
端末や job の厳密な識別が必要になった場合は、client certificate や CI 基盤が発行する
短命な ID token を用いた認証を、運用環境を含めて検討する。
