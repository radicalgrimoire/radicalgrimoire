# 配置先と storage の選択

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)（補足）  
**根拠:** [Deployment](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/deployment.md)

## 統合文案

bridge、Lore Server、reverse proxy は同一 host または別 host に配置できる。責任分界、network、永続化と recovery の要件に合わせて選ぶ。bridge の SQLite と署名鍵は永続的な local block storage 上の filesystem に置き、SQLite を NFS や object storage に直接置かない。

Lore の local store を使う場合は immutable / mutable の双方を永続化する。cloud backend の可否は配布 binary とその documentation で確認する。元文書の AWS 例は S3 単独ではなく S3 と DynamoDB を使う。cloud を選ぶ場合は repository clone / pull の転送量と egress cost も評価する。
