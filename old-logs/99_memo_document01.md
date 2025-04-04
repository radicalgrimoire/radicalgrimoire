# redmineを移行する

* 使用したredmine環境イメージ `sameersbn/redmine:3.4.2`

```
mysqldump -u redmine -ppassword -h redmine_mysql_1 redmine_production > /tmp/redmine.backup.sql
```

```
docker cp [コンテナID]：/tmp/redmine.backup.sql redmine.backup.sql
```


移動先のサーバーコンテナで

```
docker cp redmine.backup.sql [コンテナID]：/tmp/redmine.backup.sql
```

```
cd /tmp
mysql -u redmine -ppassword -h redmine_mysql_1 redmine_production < redmine.backup.sql
```
