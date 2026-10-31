# 管理 UI の repository 作成

**統合先案:** [管理 Web UI](../../operations/admin-ui.md)（新規候補）  
**根拠:** [管理 Web UI](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/admin-ui.md#機能)

## 統合文案

管理 UI の repository 作成には、対応する Lore Server と `lore.repository_create_url` が必要である。HTTP は loopback IP のみ使用でき、それ以外は信頼できる certificate を持つ HTTPS を使う。フォームは repository と `main` branch をログイン中の管理者の認証で作成し、ReBAC に同期された認可 record を確認して監査を記録する。

Name は必須、Organization は任意で、指定時は `Organization/Name` になる。各部分は半角英数字、`-`、`_`、`.` を使え、先頭の `.` は不可。Lore 側の作成、bridge への同期、監査は一つの transaction にできない。結果不明または一部成功のときは、再試行前に表示された repository ID で Lore と bridge の双方を確認する。
