# token 発行と device flow

以下は bridge `b332e35` の文書に基づく。利用する binary の revision、endpoint、権限、
token 有効期間を確認する。一般化した手順は実環境で通し検証していない。
token は credential であり、ログ、source control、chat、共有 clipboard に残さない。

## 管理 CLI による発行

IdP を使わない検証や障害時に、管理者は登録済み user の authn token を
`lore-authctl token mint-authn` で発行できる。対象 revision では `--out <path>` を
指定すると Unix では mode `0600` の file に書き込み、token 本文や token 入り command を表示しない。
出力先を指定しない場合は stdout に本文が出る。`--print-login-command` は token を含む
command を表示するため、共有 terminal や CI log では使わない。

`token mint` は repository scoped authz token の手動発行であり、authn token の発行とは
異なる。対象 binary の `--help` で出力先と引数を確認し、保存・受け渡し・期限・廃棄を管理する。
通常の repository 操作では CLI が authn token を authz token に交換する。

## Web token page

対象 revision の `/tokens` はログイン済み browser session を必要とし、現在 user に write
権限がある repository を表示する。`/tokens/mint` は same-origin header と CSRF token を
確認し、選択した repository の writer authz token を発行する。

結果には token 本文と login command が表示される。信頼できる private browser session だけで
使い、screenshot、browser history、共有 clipboard、support log に token を残さない。

## device flow

browser を持たない CLI / helper が、別の browser でログイン済み user の承認を受けて
repository token を取得する経路である。`/api/device/start` は repository と remote URL を
受け取り、device code、user code、verification URI、期限と polling 間隔を返す。
`/device` で承認し、`/api/device/token` を polling する。対象 repository の write 権限が
なければ承認できない。

code と発行 token は credential として扱う。TTL と polling 間隔は対象 revision の
`security.device_code_ttl_seconds` / `security.device_poll_interval_seconds` を確認する。
匿名 caller が到達できる start / token endpoint は edge で rate limit し、機密値をログから
除外する。[bridge 構築](../setup/lore-auth-bridge/007-nginx.md) も参照する。
