# Tailscale 越しの bridge と Lore

bridge と Lore remote を public internet に出さず、private mesh 越しに接続する構成の
確認事項。bridge `b332e35` の文書を基に整理したものであり、この手順自体の通し検証は
未実施。Tailscale の導入や tailnet ACL は環境ごとに別途設計する。

## endpoint と信頼

MagicDNS の安定した FQDN を使い、bridge の `lore.auth_url` と Lore Server の
`environment.endpoint.auth_url`、JWT issuer / audience、Lore remote と gRPC certificate
の SAN を整合させる。issuer と audience は bridge と Lore Server で対応させ、
client が使う DNS 名または IP を certificate の SAN に含める。IP を使う client には IP SAN
も必要である。[Lore Server 設定](lore-server/003-server-config.md) と
[TLS の確認](../operations/001-tls-troubleshooting.md) を参照する。

Lore Server と bridge が同一 host なら JWKS endpoint は loopback を使える。別 host では
Lore Server から到達可能な bridge HTTP endpoint が必要である。JWT、JWKS、auth endpoint、
署名鍵を変更した場合は両 service の再起動要否を確認して検証する。

## ReBAC と storage

同一 host でも FQDN を経由すると、bridge から Tailscale IP が直接の peer に見える場合が
ある。実際の送信元を確認して `security.rebac_allowed_peer_cidrs` と mesh ACL を設定する。
reverse proxy が間にある場合は、proxy も含めて公開境界で制限する。

private network でも TLS の検証、最小限の公開範囲、永続 local block storage、
[backup と復元試験](../operations/002-backup-recovery.md) は必要である。
