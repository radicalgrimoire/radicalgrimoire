# rate limit とログの機密情報

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)、[管理 Web UI](../../operations/admin-ui.md)（補足）  
**根拠:** [Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md#security)、[Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#logs)

## 統合文案

公開される device start / token、OAuth start、gRPC `StartAuthSession` には reverse proxy または load balancer 側で rate limit を設定する。bridge の per-peer 制限は多層防御であり、proxy の address が peer に見える構成では edge の制限の代替にならない。

proxy access log から OAuth code、device user code、login session nonce、token 等の query string と機密 path を除外または redact する。issued-token の metadata と token 本文を区別し、CLI / Web の一部操作は token を表示することに注意する。ログ共有前に secret と token の混入を確認する。
