# Perforce to Slack Notifier# What is this?



このリポジトリは、Perforceへのsubmit（コミット）をSlackに自動通知するためのトリガースクリプトを提供します。This Git repository explains how to notify Slack when data is submitted to Perforce.



## 概要# Howto setup

※ How to configure Slack's “Incoming Webhook” is not explained here  

Perforceのトリガー機能を利用して、チェンジリストがsubmitされた際に、その内容をSlackチャンネルに通知します。通知には以下の情報が含まれます：

Run “p4 triggers” in the server to set triggers

- Submitを実行したユーザー

- チェンジリスト番号> example:  

- 変更の詳細説明> slack.notify change-commit //test-Depot/mainline/... "/opt/perforce/servers/submit-notify.sh -u %user% -c %change% -e .env"



## 前提条件# Edit the file named .env



- Perforce サーバー（管理者権限でトリガー設定が可能）PS: Password for perforce admin user  

- Bash環境（Linux/Unix/macOS、またはWSL）USER: id for perforce admin user  

- curl コマンド

- Slack Incoming Webhook URL# About submit-notify.sh options



## セットアップ手順-u: Submitted user ID  

-c: Submitted changelist number  

### 1. Slack Incoming Webhookの設定-e: Config file. source command registers it in an environment variable.  


1. Slackワークスペースで [Incoming Webhook](https://api.slack.com/messaging/webhooks) を設定
2. 通知先チャンネルを選択
3. Webhook URLを取得（例: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX`）

### 2. スクリプトの配置

スクリプトファイルをPerforceサーバーの適切な場所に配置します。

```bash
# 例: Perforceサーバーのスクリプトディレクトリ
cp submit-notify.sh /opt/perforce/servers/
chmod +x /opt/perforce/servers/submit-notify.sh
```

### 3. 環境設定ファイル（.env）の作成

スクリプトと同じディレクトリに `.env` ファイルを作成し、以下の内容を設定します。

```bash
# Perforce管理者ユーザーのID
USER=admin_user

# Perforce管理者ユーザーのパスワード
PS=your_password

# Slack Incoming Webhook URL
CHANNEL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX
```

**セキュリティ上の注意**: `.env`ファイルには機密情報が含まれるため、適切なパーミッション設定を行ってください。

```bash
chmod 600 /opt/perforce/servers/.env
```

### 4. Perforceトリガーの設定

Perforceサーバーでトリガーを設定します。

```bash
p4 triggers
```

エディタが開くので、以下のようなトリガー設定を追加します：

```
Triggers:
    slack.notify change-commit //depot/... "/opt/perforce/servers/submit-notify.sh -u %user% -c %change% -e /opt/perforce/servers/.env"
```

**設定のポイント**:
- `slack.notify`: トリガー名（任意の名前）
- `change-commit`: トリガータイプ（submitが完了した後に実行）
- `//depot/...`: 監視対象のデポパス（必要に応じて変更）
- `-e` オプションには`.env`ファイルの絶対パスを指定

### 5. 動作確認

テスト用のファイルをsubmitして、Slackに通知が届くか確認します。

```bash
# テストファイルを作成
p4 edit //depot/test.txt
echo "test" >> test.txt
p4 submit -d "Test notification"
```

## スクリプトオプション

`submit-notify.sh` は以下のオプションを受け付けます：

| オプション | 説明 | 必須 |
|----------|------|------|
| `-u` | Submitを実行したユーザーID（Perforceの`%user%`変数） | はい |
| `-c` | Submitされたチェンジリスト番号（Perforceの`%change%`変数） | はい |
| `-e` | 環境変数設定ファイル（.env）のパス | はい |

## 通知メッセージの例

Slackに投稿されるメッセージの例：

```
@channel
john_doeさんが submit しました

**変更内容：**
```
Change 12345 by john_doe@workspace on 2025/11/11 10:30:00

    Fix bug in authentication module

Affected files ...

... //depot/src/auth.c#5 edit
... //depot/tests/test_auth.c#3 edit
```
```

## トラブルシューティング

### 通知が届かない場合

1. **ログの確認**: Perforceサーバーのトリガーログを確認
   ```bash
   p4 triggers -o
   tail -f /opt/perforce/servers/logs/trigger.log
   ```

2. **スクリプトの実行権限**: スクリプトに実行権限があるか確認
   ```bash
   ls -l /opt/perforce/servers/submit-notify.sh
   ```

3. **.envファイルの確認**: パスが正しいか、ファイルが存在するか確認
   ```bash
   cat /opt/perforce/servers/.env
   ```

4. **手動実行テスト**: スクリプトを手動で実行してエラーメッセージを確認
   ```bash
   /opt/perforce/servers/submit-notify.sh -u testuser -c 12345 -e /opt/perforce/servers/.env
   ```

### よくあるエラー

- **「エラー: .env が見つかりません」**: `.env`ファイルのパスが正しく指定されていません
- **p4 login失敗**: Perforce管理者ユーザーのID/パスワードが正しくありません
- **curl失敗**: Slack Webhook URLが正しくないか、ネットワーク接続に問題があります

## カスタマイズ

通知メッセージの内容は `submit-notify.sh` を編集することでカスタマイズできます。例えば：

- メンション先の変更（`@channel`を特定ユーザーに）
- メッセージフォーマットの変更
- 追加情報の取得（`p4 describe`のオプション変更）

## ライセンス

このプロジェクトはオープンソースです。自由に使用・改変してください。

## 貢献

バグ報告や機能追加のリクエストは、GitHubのIssueまたはPull Requestでお願いします。
