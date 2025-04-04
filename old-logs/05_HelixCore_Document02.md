# HelixCore Server

`/opt/perforce/sbin/configure-helix-p4d.sh`

作成シェルから実行
  
`Service-name` P4サーバー名称  
`P4PORT` 待ち受けポート  
`P4ROOT` サーバー側の管理フォルダ  
`Super-user` 管理者ユーザー名  
`Super-user passwd` 管理者ユーザーのパスワード  
`Unicode mode` Unicodeモードとりあえず有効にする  
`Case-sensitive` 大文字小文字を区別するかどうか。（区別しないがオススメ）

## 対話式じゃなくてそのまま起動する

`/opt/perforce/sbin/configure-helix-p4d.sh`

この実行時に `-n` を付けて実行すると対話式じゃなくて直接実行する事ができます。

`sample` 

```
/opt/perforce/sbin/configure-helix-p4d.sh \
$P4NAME -n \
-p $P4PORT \
-r $P4ROOT \
-u $P4USER \
-P $P4PASSWD \
--case $CASE_INSENSITIVE \
--unicode
```

`$P4NAME` サーバー名称  
`-p $P4PORT` ポート指定  
`-r $P4ROOT` サーバー側の管理フォルダの場所  
`-u $P4USER` 管理者アカウント名  
`-P $P4PASSWD` 管理者アカウントのパスワード  
`--case $CASE_INSENSITIVE` 大文字小文字の区別をするかどうか  
`--unicode` 文字コード判別設定できるモード  

# portをあける

```
firewall-cmd --add-port=1666/tcp --zone=public --permanent
firewall-cmd --reload
```
