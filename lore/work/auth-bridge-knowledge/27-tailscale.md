# Tailscale の接続

**統合先案:** `lore/setup/tailscale.md`（新規候補）  
**根拠:** [Tailscale](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/tailscale.md)

## 統合文案

private mesh で bridge と Lore を利用する場合は MagicDNS の安定した FQDN を使い、auth URL、JWT issuer / audience、Lore remote と certificate SAN を整合させる。同一 host の JWKS は loopback を使えるが、別 host の Lore Server には到達可能な HTTP endpoint が必要である。

同一 host でも FQDN を経由すると bridge から Tailscale IP が peer に見える場合がある。実際の接続元を確認して ReBAC allowlist と mesh ACL を設定する。private network でも persistent storage、backup、TLS と許可範囲の確認は必要である。

**確認:** 移行先には Tailscale 導入手順がなく、対象環境での通し検証も示されていない。
