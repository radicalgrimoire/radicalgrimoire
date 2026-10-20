# Lore 認証・認可の運用仕様

このページは、`lore-auth-bridge` を使う Lore 環境における、ユーザー認証、repository 認可、管理者権限、group の login IP 制限をまとめた運用仕様です。

個別の設定値は [Configuration](configuration.md)、IdP の設定は [Microsoft Entra ID](entra-id.md) と [Identity Providers](identity-providers.md)、管理コマンドは [Authctl](authctl.md) を参照してください。

## 用語

- **authn token**: user が本人であることを示す JWT。Lore CLI が login 後に保持する。
- **authz token**: 特定の repository に対する操作権限を示す JWT。repository 操作のために authn token から交換取得する。
- **bridge user**: bridge database に保存された Lore 利用者。
- **external identity**: Entra ID などの IdP が返す user identity と、bridge user の binding。
- **group**: repository grant と login IP policy に利用する user 集合。

## 認証の流れ

1. Lore CLI は bridge に interactive auth session を開始する。
2. user は browser で IdP に login する。
3. bridge は IdP の identity を検証し、登録済み bridge user または pending invitation と照合する。
4. user が利用可能であり、login IP policy にも一致した場合、bridge は authn token を発行する。
5. Lore CLI は repository 操作時に authn token を bridge へ提示し、対象 repository の authz token に交換する。
6. Lore Server は authz token を検証して repository 操作を許可または拒否する。

IdP login の成功だけでは Lore の利用は許可されません。bridge user と external identity の binding、または verified email invitation が必要です。

登録されていない user、disabled user、または login IP policy に一致しない user には authn token を発行しません。

## Entra ID identity

Entra ID provider では、bridge は tenant ID と object ID を組み合わせた `tid:oid` を subject として扱います。

email、UPN、`preferred_username` は Entra subject の識別子として使用しません。

`subject.required_tid` で tenant を固定し、別 tenant の identity を拒否します。

初回 login には通常、管理者が作成した verified email invitation が必要です。

```bash
lore-authctl --config "$CONFIG" user invite \
  --idp entra \
  --email alice@example.com \
  --name "Alice Example"
```

redirect URI、issuer、tenant ID、client secret の設定手順は [Microsoft Entra ID](entra-id.md) を参照してください。

## repository 認可

repository の `reader`、`writer`、`admin` grant は user または group に設定できます。

user に直接設定した grant と、所属 group および nested parent group から得られる grant は合算されます。

複数の grant がある場合、操作を許可する grant が一つでもあれば許可されます。

repository grant と login IP policy は別の判定です。IP policy に合格して authn token を取得しても、対象 repository の grant がなければ clone、sync、commit、push は許可されません。

```bash
lore-authctl --config "$CONFIG" grant add \
  group:project-a-writers project-a writer
```

grant の追加、確認、削除は [Authctl](authctl.md#grant-add) を参照してください。

## repository の作成と削除

repository の create と delete は repository-level grant ではなく、bridge config の `admin.admin_emails` に含まれる global admin だけが実行できます。

```yaml
admin:
  admin_emails:
    - "admin@example.com"
```

この allowlist は `/admin` Web UI の利用者も定義します。

repository の削除は hard delete です。resource と、それに関連する grant、issued token metadata、device authorization を削除します。

削除済み repository の同名再作成は可能です。

## revision history の user 表示

Lore CLI が revision author を表示する際、bridge の `GetUserInfo` API を使って `user:<UUID>` を bridge user の表示名へ解決します。

この API は resource-scoped authz token を検証し、token の署名、期限、失効状態、対象 resource を確認してから user 情報を返します。

`identity_claim = "preferred_username"` は、新規 revision に保存される identity claim の選択に関係します。既存 revision の immutable な author data は変更しません。

## group による login IP 制限

group に CIDR を設定すると、その group が user に適用される間、その CIDR からの login だけを許可できます。

```bash
lore-authctl --config "$CONFIG" group network-cidr add company-a-network 203.0.113.0/24
lore-authctl --config "$CONFIG" group network-cidr add company-b-network 198.51.100.0/24
```

判定規則は次のとおりです。

- user に適用される全 group の CIDR を集める。
- direct membership と nested parent group の CIDR を含める。
- CIDR は OR 条件で評価する。
- CIDR が一件もない user は、IP 制限なしで従来どおり login できる。
- CIDR が一件以上ある user は、いずれにも一致しなければ login token を発行しない。
- CIDR は正規化して保存する。たとえば `203.0.113.9/24` は `203.0.113.0/24` になる。

IP policy group と repository access group は別にして構いません。

たとえば、user が `company-a-network` と `project-a-writers` に所属している場合、前者の CIDR 制限と後者の repository grant が両方適用されます。

複数拠点にいる user は、専用 network group に複数 CIDR を設定するか、複数の network group に所属させます。いずれの場合も CIDR は OR で評価されます。

### 制限の範囲

この IP policy は authn token の発行時、すなわち CLI login を完了する時点だけを制限します。

発行済み authn token または authz token を使う repository 操作時に、Lore Server は送信元 IP を再判定しません。

したがって、この機能は network boundary、VPN、firewall の代替ではありません。repository 操作そのものを接続元 IP で制限する必要がある場合は、Lore Server 前段の firewall または VPN で強制してください。

### reverse proxy の要件

bridge が loopback listener の背後にあり、Nginx が gRPC を proxy する構成では、bridge は trusted loopback proxy から受け取る専用 header だけを client IP として使います。

公開 gRPC location には次を設定します。

```nginx
grpc_set_header x-lore-client-ip $remote_addr;
```

bridge は external peer が送った `x-lore-client-ip` を信用しません。

Nginx の前にさらに load balancer や proxy がある場合、`$remote_addr` が期待する client IP かを確認し、Nginx 側で trusted proxy の real-IP 設定を正しく構成してください。

## token の扱い

authn token と authz token は bearer credential です。

token 本文を shell history、CI log、shared terminal、clipboard manager、support log、browser history に残さないでください。

token TTL、signing key rotation、device flow、browser token page の注意点は [Operations](operations.md) と [Signing Keys](signing-keys.md) を参照してください。

## 運用確認

IP policy を実際の user に設定する前に、専用 test user と test group を使って次を確認します。

1. CIDR 未設定 user が従来どおり login できる。
2. 許可 CIDR から test user が login できる。
3. 許可外 IP から同じ user が login を完了できない。
4. 二つの network group の CIDR のどちらからでも login できる。
5. repository grant がない repository では、login 済みでも操作できない。

問題が起きた場合は、CIDR を group から削除すると、その user に対するその CIDR の IP 制限は直ちに次回 login から解除されます。
