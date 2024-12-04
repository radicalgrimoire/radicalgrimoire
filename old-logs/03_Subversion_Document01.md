# svnsyncを使ってリポジトリコピー

## svnsync作業用フォルダの準備

svnadminコマンドを使い、svnsync作業用フォルダの準備をする

```
svnadmin create svn_copy
```

## コピー先リポジトリ（サーバー側）とコピー元リポジトリ（サーバー側）にフックスクリプト（pre-revprop-change）を用意してサーバー側に設置する

以下内容
```
#!/bin/sh

exit 0
```

## コピー設定の初期化

```
svnsync init <移行"先"リポジトリのURL> <移行"元"リポジトリのURL>
```

## コピー実行

```
svnsync sync <移行"先"リポジトリのURL>
```
