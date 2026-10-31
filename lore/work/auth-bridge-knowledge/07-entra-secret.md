# Entra client secret の検証と更新

**統合先案:** [bridge 構築](../../setup/auth-bridge-setup.md)（補足）  
**根拠:** [Microsoft Entra ID](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/doc/setup/entra-id.md#client-secret-の更新)

## 統合文案

Entra の client secret は Secret ID ではなく Value を制限された file に保存し、設定には絶対 path を指定する。service user の読み取りを確認し、secret や token を表示しない検証 script で新しい file を試す。この検証は client credentials 要求の受理を示すだけで、browser login や Lore の権限の成功を保証しない。

更新時は新旧 secret の有効期間を重ね、別 file を検証した後に同一 filesystem で原子的に置き換える。所有権と権限を確認し、起動時に読み直す bridge を再起動する。実際の browser login と repository 操作を確認し、失敗時は旧 secret が有効な間に復旧する。
