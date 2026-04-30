# ストリーム⇒ストリームへのマージについて


```

//Mergetest/というストリームディポを作りました

この中に、
//Mergetest/mainlineというストリームと
//Mergetest/mainlineから派生した//Mergetest/development-engineという開発用ストリームを作りました。

今回はこの記事は「//Mergetest/development-engine」から「//Mergetest/mainline」へのマージ方法について記載した物です。

```



マージのビューアーを開く

![マージする](https://hexagrimoire.github.io/wiki/image/03_HelixCore/merge.01.png)

P4V 上部にある **Actions** から **Merge/Integrate...** を選択する  
※ 選択できなければ、ビューアーのフォルダトップを選択すると良いです。

## マージの設定

**Merge method** を **Specify source and target files** を選択  
![マージする](https://hexagrimoire.github.io/wiki/image/03_HelixCore/merge.02.png)

### マージ元とマージ先を選択する

* **Source files /folders:** に **マージ元を入力** する

**自動で選択入力されている** ので、  
情報が正しくなければ、 **入力されている内容を選択してからRemoveを押して**から**Add..** から正しい情報を選択入力してください。

※今回は例として、mainlineストリームからから派生した、developストリームであるdevelopment-engineを入力しています。

* **choose target files:/folders** に **マージ先を入力** 選択

マージ先を指定する  
※今回は例としてmainlineストリームを入力します

### マージ処理をどうするか？を設定する

![マージする](https://hexagrimoire.github.io/wiki/image/03_HelixCore/merge.03.png)


* **Automatically resolve files after margingのチェックボックスを選択** する

* **resolve option** から **Automatic resolve** を選択する。

* **Pending Changelist** は **new**を選択する 

## マージを実行する

![マージする](https://hexagrimoire.github.io/wiki/image/03_HelixCore/merge.04.png)

実行すると、マージされたファイルには赤い矢印が付く。

## Submitボタンを押す

![マージする](https://hexagrimoire.github.io/wiki/image/03_HelixCore/merge.05.png)

Submitを押してマージ完了
