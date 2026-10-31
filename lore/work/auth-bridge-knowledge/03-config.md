# 設定の検証と listener

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)（補足）  
**根拠:** [Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md)、[Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md#ports)

## 統合文案

対象 revision の YAML は各設定 object の未知の key を parse error として扱う。設定例を流用するときは対象 binary の schema に合わせ、綴り間違いや未対応項目を残さない。HTTP listener は login、health、JWKS、device flow と任意の管理 UI を提供し、gRPC listener は `UrcAuthApi` と `RebacApi` を提供する。外部公開先と内部 listener は別々に確認する。標準例の loopback port と、個別の構築手順で使う port は異なり得る。
