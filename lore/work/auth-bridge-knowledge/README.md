# lore-auth-bridge 文書の統合候補

`lore-auth-bridge` の文書から、移行先の Lore 文書に統合できる知識を一項目一ファイルに分けた作業用資料。本文はそのまま統合のたたき台にできるが、既存文書への反映や動作確認を完了したものではない。

- 調査対象: bridge の `b332e35b42204c23271f02bbb6f4aa6ae9e25f71`、移行先の `97b8958b6eb83a2c45d93d65eb1fe6391b0f2c38`。
- 各候補は対象 revision の文書に基づく。運用中の binary・設定・挙動との互換性を確認し、一般化された未検証手順を実機検証済みと扱わない。
- 「補足」は移行先に関連する記述が既にあるもの。「新規候補」は移行先に対応する独立した説明がないもの。統合先は提案であり、未作成のページもある。
- 調査は文書の統合候補の棚卸しであり、ソース全体の機能監査ではない。文書にない機能まで網羅したとは主張しない。

## 候補一覧

| 番号 | 要件 | 区分 |
| --- | --- | --- |
| 01 | [認証・認可の経路](01-auth-flow.md) | 補足 |
| 02 | [実行ファイルと対応バージョン](02-binaries.md) | 補足 |
| 03 | [設定の検証と listener](03-config.md) | 補足 |
| 04 | [IdP と provider ID](04-providers.md) | 新規候補 |
| 05 | [確認済みメールによる招待](05-invitation.md) | 補足 |
| 06 | [Entra identity の明示的な binding](06-entra-binding.md) | 補足 |
| 07 | [Entra client secret の検証と更新](07-entra-secret.md) | 補足 |
| 08 | [JWT と署名鍵](08-signing.md) | 補足 |
| 09 | [repository と grant の識別](09-grants.md) | 補足 |
| 10 | [グループの接続元 CIDR](10-group-cidr.md) | 補足 |
| 11 | [nested group の移行](11-nested-groups.md) | 補足 |
| 12 | [管理 UI の有効化と境界](12-admin-boundary.md) | 補足 |
| 13 | [管理 UI の Entra 登録](13-admin-entra.md) | 補足 |
| 14 | [管理 UI の repository 作成](14-admin-repository-create.md) | 新規候補 |
| 15 | [管理 UI の直接・実効権限](15-admin-access.md) | 補足 |
| 16 | [メンテナンスと repository 無効化](16-maintenance.md) | 新規候補 |
| 17 | [管理 UI の service account 作成](17-admin-service-account.md) | 補足 |
| 18 | [手動 token 発行](18-manual-token.md) | 新規候補 |
| 19 | [Web token page](19-web-token.md) | 新規候補 |
| 20 | [device flow](20-device-flow.md) | 新規候補 |
| 21 | [ReBAC と reverse proxy の境界](21-rebac-proxy.md) | 補足 |
| 22 | [rate limit とログの機密情報](22-logging-rate-limit.md) | 補足 |
| 23 | [TLS の信頼と診断](23-tls.md) | 補足 |
| 24 | [Lore Server の接続整合性](24-loreserver.md) | 補足 |
| 25 | [配置先と storage の選択](25-deployment.md) | 補足 |
| 26 | [SQLite と鍵のバックアップ](26-backup.md) | 補足 |
| 27 | [Tailscale の接続](27-tailscale.md) | 新規候補 |
| 28 | [IdP なしのローカル検証](28-quickstart.md) | 新規候補 |
| 29 | [管理者・IdP 障害からの復旧](29-recovery.md) | 補足 |
| 30 | [開発・互換性テスト](30-testing.md) | 新規候補 |
| 31 | [Entra 連携の検証根拠](31-evidence.md) | 補足 |

## 元文書の対応表と扱い

| 元文書 | 対応候補・扱い |
| --- | --- |
| [README](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/README.md) | 01、02、08、30 |
| [Setup Guide](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup-guide.md) | 01、04、05、18、28 |
| [Configuration](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/configuration.md) | 03、04、05、08、12、20、21、22、24 |
| [Deployment](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/deployment.md) | 21、25、27 |
| [Operations](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/operations.md) | 03、19、20、22、26、29 |
| [TLS](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/tls.md) | 23 |
| [Signing Keys](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/signing-keys.md) | 08、26 |
| [Loreserver](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/loreserver.md) | 09、21、23、24 |
| [Authctl](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/authctl.md) | 05、06、08、09、11、17、18、29 |
| [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md) | 10–17、29 |
| [Identity Providers](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/identity-providers.md) | 04–06、18 |
| [Microsoft Entra ID](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id.md) | 05–07 |
| [Hands-on Quickstart](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/hands-on-quickstart.md) | 18、23、24、28 |
| [Tailscale](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/tailscale.md) | 27 |
| [Entra 変更根拠](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id-integration-evidence.md)、[更新履歴](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id-bridge-update-history.md) | 06、31。削除済み onboarding script は現行手順にしない |
| [実機構築記録](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/on-prem-entra-lore-server.md) | 固有ホスト・破壊的な転送例は一般手順に転記しない。既存の [作業記録](../server-193-bridge-tls.md)、[構築手順](../../setup/auth-bridge-setup.md) と照合する |
| [E2E harness](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/crates/lore-auth-e2e/README.md) | 30 |
| `NOTICE.md` | 同梱資産のライセンス通知であり、運用知識として移植しない。配布時には元の通知を維持する |

## 統合前の注意

- 元の Configuration は nested group を評価対象と記述する一方、Authctl / 管理 UI は新規作成禁止と既存関係を解除する migration を記載している。[11](11-nested-groups.md) の revision 条件を優先して確認する。
- 元の Authctl は `key generate`、既存構築手順は `signing-key generate` を使う。対象 binary の `--help` で確認し、置換を決めつけない。
- 作業記録にある実機での成功と、本資料の提案文・一般化した手順の検証状況は別である。secret、token、個人や内部環境の値は統合文に転記しない。
