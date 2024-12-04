ソースからインストールする方法について簡単に解説  
  
参考元：  
（というか、ここに書いてある事はほぼココに記載されている情報）  
https://manualmaton.com/2023/12/21/ubuntu20-04のopensshを8-2p1から9-6-1pにアップデート。/  
  
# 必要なモジュールのインストール  
apt-get -qy update && apt-get -qy install --no-install-recommends build-essential ca-certificates checkinstall zlib1g-dev wget  

# ソースのダウンロード  
cd /usr/local/src  
wget https://www.openssl.org/source/openssl-3.1.4.tar.gz && tar -xvzf openssl-3.1.4.tar.gz  
wget -c http://mirror.exonetric.net/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz && tar -xvzf openssh-9.6p1.tar.gz  

# ソースビルド＆インストール  
cd /usr/local/src/openssl-3.1.4  
./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib && make && make install && make clean  
echo /usr/local/ssl/lib64 > /etc/ld.so.conf.d/openssl-3.1.4.conf  
ldconfig -v  
PATH "$PATH:/usr/local/ssl/bin"  