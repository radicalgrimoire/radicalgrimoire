# 構築について

https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.install.html

このリンクにある手順通りにインストールを進めれば構築できるが  
ここではコンテナで構築する際に工夫した事を記載する  

# インストール後の構成

> /opt/perforce/sbin/configure-helix-p4d.sh

インストールをした後、実際のhelix-p4dサーバーを構築するには  
このスクリプトを実行する必要がある

コンテナを起動したらすぐに設定済みの構築ができるようにしたかったので
