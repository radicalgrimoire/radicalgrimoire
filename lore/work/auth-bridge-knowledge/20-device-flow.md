# device flow

**統合先案:** `lore/operations/token-flows.md`（新規候補）  
**根拠:** [Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#device-flow)

## 統合文案

device flow は browser を持たない CLI / helper が、別の browser でログイン済み user の承認を受けて repository token を取得する経路である。`/api/device/start` は repository と remote URL を受け取り device code、user code、verification URI、期限と polling 間隔を返す。`/device` で承認し、`/api/device/token` を polling する。対象 repository への write 権限がなければ承認できない。

code と発行された token は credential として扱う。TTL と polling 間隔を設定し、匿名で到達する start / token endpoint は edge で rate limit する。
