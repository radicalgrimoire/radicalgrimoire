> [!NOTE]
> Perforceではサブミットをしないで、他の人にファイルを共有する事が可能です  
> その機能の事を `Shelve` と言います  

# チェックアウト

Shelveをするには、まずチェックアウトをします

![shelve-and-unshelve-files-01.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-01.png)

defaultではなく、Newを選びましょう  
Shelveでファイルを共有するには、共有する相手から見えるようにチェンジリストに番号を割り振っておく必要があります

![shelve-and-unshelve-files-02.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-02.png)


# Shelve する

チェンジリストを選択して、`Shelve Files...` を選択

![shelve-and-unshelve-files-03.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-03.png)

２つチェックが入ってると思いますが、そのまま気にせずShelveを実行します  
※もし入ってなかったら入れてください

![shelve-and-unshelve-files-04.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-04.png)

# Unshelve する

共有相手から、教えてもらったチェンジリストの番号を探して、Shelve状態のファイルがちゃんとある事を確認します  
そして、`Unshelve files...` を選択します  

![shelve-and-unshelve-files-05.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-05.png)

Overwrite...~にチェックを入れて、Unshelveを選択します

![shelve-and-unshelve-files-06.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-06.png)

自分のローカルにShelve状態のファイルが落ちてきます。

## 他の人が現在作業中のチェンジリストを確認するには？

UserとWorkSpaceの項目を空欄にしましょう

![shelve-and-unshelve-files-07.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-07.png)


# ファイルの共有（Shelve）が終わったら…

Delete Shelved... を選択して、ファイルの共有状態を解除します

![shelve-and-unshelve-files-08.png](../../../images/perforce/user-guide/p4v/shelve-and-unshelve-files/shelve-and-unshelve-files-08.png)

共有状態も無くしたチェンジリストは削除しておきましょう。
