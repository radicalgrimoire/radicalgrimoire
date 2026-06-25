# バックアップとリストア


## バックアップ

```
p4 admin stop
p4 admin checkpoint -z checkpoint_file
p4 admin start
```

## リストア

```
p4 admin stop
p4d -r [db.ファイルを展開するフォルダ] -z -jr checkpoint_file.gz
p4 admin start
```
