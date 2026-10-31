# IdP なしのローカル検証

**統合先案:** `lore/setup/local-auth-quickstart.md`（新規候補）  
**根拠:** [Hands-on Quickstart](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/hands-on-quickstart.md)

## 統合文案

外部 IdP を使わない検証では、隔離された新しい作業 directory に TLS、bridge config、DB と署名鍵を用意し、手動 user と authn token を作る。bridge の health / JWKS を確認してから Lore Server を起動し、CLI login、repository 作成、bridge への同期、writer grant、`check`、clone の順に確認する。

これは本番の Entra login や proxy 境界の確認ではない。既存 DB や store を初期化・削除せず、token と秘密鍵を保護する。詳細な command と certificate の信頼設定は対象 binary の revision に合わせて検証した後に採用する。
