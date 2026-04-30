gitのログの完全削除  

```
git checkout --orphan tmp
git commit -m "Initial Commit"
git checkout -B main
git branch -d tmp
```

記事元  
https://qiita.com/okashoi/items/6b1a8ca9a4b001200167