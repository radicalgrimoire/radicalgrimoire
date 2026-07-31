# Helix Core 管理者向け手順

Helix Core (Perforce) の構築、運用、障害対応に関する手順です。作業前に対象サーバーのバージョン、`P4ROOT`、サービス管理方法、バックアップ状態を確認してください。

## 構築

* [Helix p4d のコンテナ構築](helix-p4d-setup.md)
* [コミット/エッジサーバー構成](commit-edge-server-setup.md)
* [トリガーの公式ドキュメント](trigger-configuration.md)
* [大文字・小文字チェック用トリガー](p4-trigger-case-check.md)

## 運用・障害対応

* [障害対応の判断フロー](incident-response-decision-flow.md)
* [db.have の復旧](db-have-recovery.md)
* [チェックポイントからの復旧](checkpoint-backup-and-restore.md)
* [SSL 証明書の更新](helix-p4d-ssl-certificate-renewal.md)
* [他ユーザーのチェックアウトを解除する](revoke-other-user-checkout.md)
* [shelve に起因するロックを解除する](unlock-shelved-file.md)
* [Helix Swarm](helix-swarm.md)