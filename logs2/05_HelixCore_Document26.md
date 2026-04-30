
# コマンドライン
```
StreamA：mainlineストリーム
StreamB：mainlineから派生したdevelopmentストリーム
```

こんな感じでコマンドラインでマージして

```
p4 integrate //Hoge/StreamB/... //Hoge/StreamA/...
```

```
p4 resolve
p4 add ./*
p4 submit -d "コメントを書く"
```


# マージ元のDescription情報を調べる

mainlineからdevelopmentへのマージをする事を例に

integrate でマージするときに -nを付けて実行するとマージ処理のテストを行う事ができる。


```
p4 -Ztag integrate -n //YBB/mainline/... //YBB/development/...
```

これで、２つのファイルの差分を抽出

```
... depotFile //YBB/development/1.txt
... clientFile D:\Projects\App\super_GSPCD527_development_207\1.txt
... workRev 1
... action integrate
... fromFile //YBB/mainline/1.txt
... startFromRev 1
... endFromRev 2

... depotFile //YBB/development/2.txt
... clientFile D:\Projects\App\super_GSPCD527_development_207\2.txt
... workRev 3
... action integrate
... fromFile //YBB/mainline/2.txt
... startFromRev 3
... endFromRev 6

```

`depotFile` 差分の出たマージ先のファイル  
`workRev` 差分のsubmit情報個数  
`startFromRev` 差分開始ファイルリビジョン番号  
`endFromRev` 差分終了ファイルリビジョン番号  

マージ元のsubmit 情報を取得する

```
$ p4 -Ztag filelog -l //YBB/mainline/1.txt#1,#2 //YBB/mainline/2.txt#3,#6
... depotFile //YBB/mainline/1.txt
... rev0 2
... change0 14
... action0 edit
... type0 text
... time0 1584955270
... user0 super
... client0 super_GSPCD527_mainline_8963
... fileSize0 18
... digest0 2E7A45274230AC01B42F8312D500AB14
... desc0 genkidesu

... rev1 1
... change1 2
... action1 add
... type1 text
... time1 1584946521
... user1 super
... client1 super_GSPCD527_mainline_8963
... fileSize1 10
... digest1 E807F1FCF82D132F9BB018CA6738A19F
... desc1 1234567890

... how1,0 branch into
... file1,0 //YBB/development/1.txt
... srev1,0 #none
... erev1,0 #1

... depotFile //YBB/mainline/2.txt
... rev0 6
... change0 14
... action0 edit
... type0 text
... time0 1584955270
... user0 super
... client0 super_GSPCD527_mainline_8963
... fileSize0 52
... digest0 0A805E7B63B2D38A0D0ABD3E1AA990B4
... desc0 genkidesu

... rev1 5
... change1 13
... action1 edit
... type1 text
... time1 1584950347
... user1 super
... client1 super_GSPCD527_mainline_8963
... fileSize1 42
... digest1 4C87CA6E3DEA03EA826731A70F80FDB9
... desc1 adadadadadad

... rev2 4
... change2 12
... action2 edit
... type2 text
... time2 1584950040
... user2 super
... client2 super_GSPCD527_mainline_8963
... fileSize2 33
... digest2 99C6DFBF5B0E313FC389549DB71C210F
... desc2 dual

... rev3 3
... change3 10
... action3 edit
... type3 text
... time3 1584949692
... user3 super
... client3 super_GSPCD527_mainline_8963
... fileSize3 33
... digest3 99C6DFBF5B0E313FC389549DB71C210F
... desc3 test2

... how3,0 copy into
... file3,0 //YBB/development/2.txt
... srev3,0 #2
... erev3,0 #3

```

この情報を時間でソートして、  
ファイルリビジョン指定してマージをする。