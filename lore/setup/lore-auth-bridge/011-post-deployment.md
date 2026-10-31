# 導入後

[構築手順と前提](README.md) を確認する。一般化した手順は別環境で通し検証していない。

DB、JWT signing key、設定を Lore store と同時点の recovery set に含め、復元試験を行う。
Entra client secret と certificate の期限を管理し、certificate は client と runner に先に
配布してから切り替える。実機での更新・証明書運用は
[作業記録](../../work/) を参照する。
