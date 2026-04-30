# P4Vをインストールする

https://www.perforce.com/downloads

Helix Visual Client (P4V)をダウンロード  

インストール画面にて、  
P4V、P4Merge、P4Adminを選択してインストールする。

# P4Adminを起動する

**P4Admin**を起動

![P4Adminヲグイン](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.1.png)

**Server:** にPerforceのサーバーとポートを指定して書く  
**User:** には、環境構築時に作った管理者アカウント名を指定する

**OKを押す**とパスワードを聞かれるので構築時に入力した管理者アカウントのパスワードを入力  
1回入力したらパスワードは2回目以降は省略される。

**Browse...** は、今作られているユーザー一覧が見れる。  
※要:管理者アカウントでのログインセッション


ログインしたらこんな事を聞かれるかもしれない。

![P4Adminヲクニン](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.2.png)

**Trust this fingerprint**をにチェックいれてConnectを押すでOK

# ユーザーを作る

**P4Adminから作る**

![P4Adminヲーザー一覧を開く](https://raw.githubusercontent.com/hexagrimoire/WorkNote/main/image/perforce.3.png)

* **Users & Groups** を選択して、ユーザー一覧を表示する  
一覧の枠内で右クリックしてNew User...を選択

* File　⇒　New　から**User**を選択


必要な情報を入力して作成する  
※アカウントタイプはスタンダードでOK

# ディポを作る

ディポとは　⇒　サーバー側のリポジトリの事

![P4Adminディポ一覧を開く](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.4.2.png)


File　⇒　New　から**Depot**を選択

Depot名を入力して
Depottypeは「**Stream**」を選択して作成

![P4Adminディポ一覧を開く](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.4.png)

# メインラインストリームを作る

ワークスペースを適当に作る（後述）  
本項で作成したワークスペースは破棄してもあとで設定を変更するのでも何でも良いです。


![Stream](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.8.png)

P4Vを起動  
File　⇒　New　から**Stream**を選択


![Stream](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.7.png)

Stream type:  
mainlineストリームを作っていなければmainline以外選択できない  
gitでいうところのmasterブランチに相当する？

Stream name:  
ストリーム名称。

depot:  
どこのdepotに作成するか？
今回は先述で作成したdepotに作成する。

Location:  
理由ない限り特にいじらない方向で。

description、他:
略

これで作成する。

# ワークスペースの情報を変更する

View ⇒ WorkSpaces を選択するとメインビューにWorkSpaceのタブが表示されるので、タブ変更する。

![WORKSPACEはここから](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.10.png)

ワークスペースの作成する時に出る入力画面と同じ物がでるので
先述作成したメインラインストリームとWorkSpaceRoot等を必要に応じて変更する。

# ワークスペースを作る

ワークスペースとは　⇒　ローカルの作業環境

![WORKSPACEはここから](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.5.png)

ここから作る

![ワークスペース](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/perforce.6.png)

`WorkSpaceName` 複数Perforceリポジトリを作った時にわかりやすくするための名称付け。自分がわかるように設定するか、プロジェクト側の指示に従う  
`WorkSpaceRoot` リポジトリをチェックアウトをする所  
`Stream` 作っていればBrowse..から選択

