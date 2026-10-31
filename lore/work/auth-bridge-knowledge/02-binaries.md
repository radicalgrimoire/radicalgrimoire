# 実行ファイルと対応バージョン

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)（補足）  
**根拠:** [bridge README](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/README.md#実行ファイル)

## 統合文案

bridge の配布物には HTTP/gRPC サービス `lore-auth-server`、管理 CLI `lore-authctl`、Lore binary の JWT claim contract を確認する `lore-claimprobe` がある。bridge の文書には Lore CLI / Server `0.8.4+283` で login、repository 作成、token exchange、clone を確認した記録がある。これはすべての版の互換性を保証しない。新しい組み合わせでは binary の出所と revision を固定し、claim contract と実際の操作を確認する。
