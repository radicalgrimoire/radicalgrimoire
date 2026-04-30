# UTCからJSTに変更する

`CentOS 7`から`timedatectl`コマンドが使えるのでそれで行う。

```
timedatectl set-timezone Asia/Tokyo  
```

※参考 設定可能なタイムゾーン一覧の確認
```
timedatectl list-timezones
```