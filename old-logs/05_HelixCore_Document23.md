# ファイル名を変更する際の注意

1. `hoge.uasset`というファイルがある。
2. `hoge.uasset`の名前を`Hoge.uasset`に変える
3. `Hoge.uasset`をサーバー側に追加してsubmitする

ファイル名のリネーム等で大文字から小文字などに変更するだけとかは特に注意が必要です。

この場合はサーバー側に`hoge.uasset`を消すsubmitをしてないので
サーバー側にはまだ`hoge.uasset`は残ったままの状態です。
たったこの手順だけでサーバー側に同じ名前の2つのファイルができてしまいます  

この状態になると`UnrealGameSyncでSyncが出来なくなったり`いろいろと不具合が生じます  
ファイル名を変更する場合は、先に`元ファイルをちゃんと削除submit`しましょう。 

# もし仮に追加してしまったら

## 1. 重複ファイルの確認

![trouble.image.11.png](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/trouble.image.11.png)

Depotタブから重複ファイル状況を確認する

## 2. P4V上から問題の重複ファイルフォルダをリネームする

![trouble.image.12.png](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/trouble.image.12.png)

Depotタブ上から問題のファイルを選択した状態で  
`右クリック`してリネーム

## 3. p4adminで問題のファイルの削除しなければいけないファイルをobliterateする

※p4dサーバー管理者操作する

![trouble.image.13.png](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/trouble.image.13.png)

これでOK