# Lore Server 導入後の運用

bridge の [利用者登録](../lore-auth-bridge/010-user-onboarding.md) で
identity binding と repository grant を設定してから、実 client で login と clone を確認する。
CI の login や writer 操作は別途実行して確認する。DB、JWT signing key、Lore store、設定を
同じ時点の recovery set として backup し、復元試験を行う。

一般化した構築手順は別環境で通し検証していない。実機での作業は
[作業記録](../../work/) を参照する。
