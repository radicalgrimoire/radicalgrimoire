# Web token page

**統合先案:** `lore/operations/token-flows.md`（新規候補）  
**根拠:** [Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#web-token-page)

## 統合文案

対象 revision の `/tokens` はログイン済み browser session を必要とし、現在 user に write 権限がある repository を表示する。`/tokens/mint` は same-origin header と CSRF token を確認し、選択した repository の writer authz token を発行する。

結果には token 本文と login command が表示されるため、信頼できる private browser session だけで使う。screenshot、browser history、共有 clipboard、support log に token を残さない。
