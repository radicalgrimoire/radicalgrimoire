# ReBAC と reverse proxy の境界

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)（補足）  
**根拠:** [Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#security)、[Loreserver](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/loreserver.md#environmentendpoint)

## 統合文案

`RebacApi` は Lore Server からの resource lifecycle sync 用として制限する。元文書の stock Lore Server は ReBAC client に service token metadata を送らないため、bridge の `rebac_allowed_peer_cidrs` と network boundary を使う。空の allowlist は loopback peer のみを許可する。

reverse proxy が loopback から転送すると bridge の peer 判定には proxy が見える。そのため edge 側でも `/ucs.auth.RebacApi/*` を実際の Lore Server 送信元に限定する。公開 client 向け `UrcAuthApi` と混同せず、許可・拒否の両方を実際の経路で検証する。
