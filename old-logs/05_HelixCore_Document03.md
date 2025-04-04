# HelixCore ProxyServer

構築手順簡易まとめ

# パッケージをインストールする

## リポジトリ追加  

[package-based installation](03_HelixCore_Document01)

## インストール

* For APT (Ubuntu)
```
sudo apt-get install helix-p4d helix-proxy
```
* For YUM (Red Hat Enterprise Linux or CentOS)
```
sudo yum install -y helix-p4d helix-proxy
```

# HelixCore ProxyServer(p4p)を起動する

## コマンドを実行

コマンドの本体はココにあるが気にせずに実行

`/opt/perforce/sbin/p4p`

```
ex)
sudo -E -u perforce p4d -Gc
sudo -E -u perforce p4d -Gf
sudo -E -u perforce p4 trust -y
sudo -E -u perforce p4p -d -p ${P4PPORT} -t ${P4PORT} -r ${P4PCACHE} -L ${P4PLOGFILE} -v 3
```

`-p ${P4PPORT}` p4p起動アドレス  
`-t ${P4PORT}` p4d対象  
`-r ${P4PCACHE}` キャッシュフォルダ  
`-L ${P4PLOGFILE}` ログファイルを指定  
`-v 3`  

# portをあける

```
firewall-cmd --add-port=1777/tcp --zone=public --permanent
firewall-cmd --reload
```
