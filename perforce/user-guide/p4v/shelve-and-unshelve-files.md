> [!NOTE]
> Perforceではサブミットをしないで、他の人にファイルを共有する事が可能です  
> その機能の事を `Shelve` と言います  

# チェックアウト

Shelveをするには、まずチェックアウトをします

![01_Shelve01.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve01.png)   

defaultではなく、Newを選びましょう  
Shelveでファイルを共有するには、共有する相手から見えるようにチェンジリストに番号を割り振っておく必要があります

![01_Shelve02.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve02.png)   


# Shelve する

チェンジリストを選択して、`Shelve Files...` を選択

![01_Shelve03.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve03.png)   

２つチェックが入ってると思いますが、そのまま気にせずShelveを実行します  
※もし入ってなかったら入れてください

![01_Shelve04.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve04.png)   

# Unshelve する

共有相手から、教えてもらったチェンジリストの番号を探して、Shelve状態のファイルがちゃんとある事を確認します  
そして、`Unshelve files...` を選択します  

![01_Shelve06.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve06.png)   

Overwrite...~にチェックを入れて、Unshelveを選択します

![01_Shelve07.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve07.png)   

自分のローカルにShelve状態のファイルが落ちてきます。

## 他の人が現在作業中のチェンジリストを確認するには？

UserとWorkSpaceの項目を空欄にしましょう

![01_Shelve08.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve08.png)   


# ファイルの共有（Shelve）が終わったら…

Delete Shelved... を選択して、ファイルの共有状態を解除します

![01_Shelve05.png](https://raw.githubusercontent.com/radicalgrimoire/radicalgrimoire/main/images/01_Shelve05.png)   

共有状態も無くしたチェンジリストは削除しておきましょう。
