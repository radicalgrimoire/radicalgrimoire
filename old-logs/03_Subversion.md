# Subversion

* Subversion 本体  
https://subversion.apache.org/  

* コマンドラインが必要（[VisualSVN](https://www.visualsvn.com/)）  
Apache Subversion command line tools  
> https://www.visualsvn.com/downloads/

## SubversionEdge
http://www.collabnet.jp/products/subversion  
> https://hub.docker.com/r/mamohr/subversion-edge/

フックスクリプトを有効にする。
```
> /opt/csvn/data/conf/security.properties  
> hook.script.editor.enabled=false // trueに変更すると有効化  
```

* [SVNsyncを使ってリポジトリコピー](03_Subversion_Document01)
* [TortoiseSVN](https://tortoisesvn.net/)
