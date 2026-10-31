# グループの接続元 CIDR

**統合先案:** [authctl 操作](../../operations/authctl.md)、[CI Service Account](../../operations/ci-service-account.md)（補足）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

group の許可接続元は IPv4 / IPv6 の address または CIDR で設定でき、単一 address は `/32` または `/128` として扱われる。user に適用される group の CIDR は合算される。適用 CIDR が一つもない通常 user の login には IP 制限がないが、service account の認証には一致する CIDR が必要である。

NAT や proxy を含む実際の接続元を確認し、trusted proxy の設定も対象 revision に合わせる。CIDR の変更は発行済み token を無効化しない。
