# 同期はすれどもサブミットできないようにする

開発中で`同期は必要だけど、作業者からサブミットはしない`ファイルなんて物も開発ではあると思います  
今回はその方法をいくつか記載します

# 1. 別ストリームからimportをしてファイルを持ってくる

stream depotを活用している場合は  
別ストリームから該当のファイルを持ってくる方法がある

# 2. p4 protectでアクセス制御する

.uproject

```
=write user * * -//....uproject
```

これでユーザー全員.uprojectを編集はできるがサブミットできないようにできる。


# 元ドキュメント

* [About stream views](https://www.perforce.com/manuals/p4v/Content/P4V/streams.views.html)
* [p4 protect](https://www.perforce.com/perforce/doc.current/manuals/p4sag/Content/P4SAG/protections.set.html)