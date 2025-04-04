# sikakuitiran

https://www.jitec.ipa.go.jp/1_11seido/seido_gaiyo.html

# PCローカルを活用したJenkins開発

公式
```
Jenkins  
https://jenkins.io/
```
download ボタンを押してダウンロードページに飛ぶ
左側の下部にあるLTS版のWindowsのインストールをダウンロードする。




Convoy install

    yum update -y
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
    yum install -y wget nmap
    curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine
    chmod +x /usr/local/bin/docker-machine
    curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    systemctl enable docker.service
    systemctl start docker.service
    
    pushd /home/vagrant
    wget https://github.com/rancher/convoy/releases/download/v0.5.2/convoy.tar.gz
    tar xvzf convoy.tar.gz
    sudo cp convoy/convoy convoy/convoy-pdata_tools /usr/local/bin/
    sudo mkdir -p /etc/docker/plugins/
    sudo bash -c 'echo "unix:///var/run/convoy/convoy.sock" > /etc/docker/plugins/convoy.spec'
    truncate -s 100G data.vol
    truncate -s 1G metadata.vol
    sudo losetup /dev/loop5 data.vol
    sudo losetup /dev/loop6 metadata.vol
    sudo convoy daemon --drivers devicemapper --driver-opts dm.datadev=/dev/loop5 --driver-opts dm.metadatadev=/dev/loop6 &
    popd

    pushd /usr/bin
    ln -s /usr/local/bin/docker-machine docker-machine
    ln -s /usr/local/bin/docker-compose docker-compose
    ln -s /usr/local/bin/convoy convoy
    ln -s /usr/local/bin/convoy-pdata_tools convoy-pdata_tools
    popd

----
https://qiita.com/bezeklik/items/9766003c19f9664602fe


yum install epel-release  
yum install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm


----

https://developer.github.com/v3/guides/managing-deploy-keys/ 
https://qiita.com/yuch_i/items/44d224112382b5f1c8eb

----

xcodebuild archive
-archivePath [アーカイブのパス]
-scheme Unity-iPhone
-configuration development

xcodebuild
-exportArchive
-archivePath [アーカイブのパス]
-exportPath [ipaファイルのエクスポート先]
-exportOptionsPlist Info.plist

----

紹介記事  
https://www.atmarkit.co.jp/ait/articles/1708/31/news011.html  

Docker  
https://github.com/jboss-dockerfiles/keycloak/tree/master/docker-compose-examples  
https://hub.docker.com/r/jboss/keycloak/  



[リモートフォワーディング](RemoteForwarding)  




https://www.rem-system.com/win2019-azure-backup/#3-1_Recovery_Services




https://qiita.com/oh_rusty_nail/items/4a189a3b617e56081d6c
https://qiita.com/roworks/items/7ef12acabf9679561d84

***
HashIds  
https://hashids.org/

***

|name  |URL  |
|---|---|
|PHP  |http://php.net  |
|CakePHP|https://cakephp.org   |
|Laravel|https://laravel.com   |
|Apple  |https://developer.apple.com/jp/documentation/   |
|CygamesDocument|https://speakerdeck.com/cygames/  |
|PHPStorm|https://www.jetbrains.com/phpstorm/  |
|riken|http://ftp.riken.jp     |
|Bootstrap|http://getbootstrap.com |
|Unity|https://unity3d.com/jp |

# DocumentLink

https://blog.adachin.me/archives/10849  
https://qiita.com/mookjp/items/9ae307e15d17796c1295  
https://cloud-work.jp/windows_pc/windows/win2mac_vnc/  
https://techtarget.itmedia.co.jp/tt/news/1501/23/news03.html  
https://qiita.com/muran001/items/14f19959d4723ffc29cc  
https://knowledge.sakura.ad.jp/1552/  
http://fnya.cocolog-nifty.com/blog/2014/01/visual-studio-1.html  
http://blog.manaten.net/entry/windows-phplint  

-----------


sudo convoy snapshot create dokuwiki_conf --name dokuwiki_conf_2019_12_05
sudo convoy snapshot create dokuwiki_data --name dokuwiki_data_2019_12_05
sudo convoy snapshot create dokuwiki_plugins --name dokuwiki_plugins_2019_12_05
sudo convoy snapshot create dokuwiki_tpl --name dokuwiki_tpl_2019_12_05


sudo convoy backup create dokuwiki_conf_2019_12_05 --dest vfs:///opt/convoy/
sudo convoy backup create dokuwiki_data_2019_12_05 --dest vfs:///opt/convoy/
sudo convoy backup create dokuwiki_plugins_2019_12_05 --dest vfs:///opt/convoy/
sudo convoy backup create dokuwiki_tpl_2019_12_05 --dest vfs:///opt/convoy/


                "BackupURL": "vfs:///opt/convoy/?backup=backup-000181acd414493a\u0026volume=dokuwiki_conf",
                "BackupURL": "vfs:///opt/convoy/?backup=backup-337d239754914f6e\u0026volume=dokuwiki_data",
                "BackupURL": "vfs:///opt/convoy/?backup=backup-ba3d5e81f3094db9\u0026volume=dokuwiki_tpl",
                "BackupURL": "vfs:///opt/convoy/?backup=backup-cfccfe7de2604977\u0026volume=dokuwiki_plugins",



convoy create dokuwiki_conf --backup vfs:///opt/convoy/?backup=backup-000181acd414493a\u0026volume=dokuwiki_conf
convoy create dokuwiki_data --backup vfs:///opt/convoy/?backup=backup-337d239754914f6e\u0026volume=dokuwiki_data
convoy create dokuwiki_tpl --backup vfs:///opt/convoy/?backup=backup-ba3d5e81f3094db9\u0026volume=dokuwiki_tpl
convoy create dokuwiki_plugins --backup vfs:///opt/convoy/?backup=backup-cfccfe7de2604977\u0026volume=dokuwiki_plugins

sudo convoy daemon --drivers devicemapper --driver-opts dm.datadev=/dev/loop5 --driver-opts dm.metadatadev=/dev/loop6 &

https://icondecotter.jp/blog/2016/03/17/centos7%E3%81%A7home%E3%83%91%E3%83%BC%E3%83%86%E3%82%A3%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AE%E5%AE%B9%E9%87%8F%E3%82%92%E5%89%8A%E6%B8%9B%E3%81%97%E3%81%A6root%E3%81%AB%E5%89%B2%E3%82%8A%E5%BD%93/

