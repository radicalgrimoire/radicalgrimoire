# TLS の信頼と診断

**統合先案:** [TLS の確認と切り分け](../../operations/tls-troubleshooting.md)（補足）  
**根拠:** [TLS](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/tls.md)

## 統合文案

bridge の HTTP/JWKS と gRPC は別 endpoint であり、auth exchange と ReBAC には gRPC over TLS の到達性が必要である。gRPC certificate の SAN は client が使う DNS 名または IP と一致させる。mkcert の leaf ではなく発行元 root CA を信頼し、自己署名 server certificate を trust anchor とする構成では対象 revision の挙動を確認する。

`lore auth login --token` の成功は token のローカル保存だけの場合があり、gRPC 接続の成功を意味しない。`Failed to connect to rebac service` は TLS trust を含む複数の原因を調査する。`openssl verify` は chain の一確認であり、host 名、gRPC、認可の実動作の代替にはならない。
