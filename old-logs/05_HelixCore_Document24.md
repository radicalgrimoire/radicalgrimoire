# 文字コードの設定変更

**コマンドラインから変更は可能ですが、P4Vから変更した方が無難です**  
P4CHARSETとクライアント文字エンコードの両方の変更を試してみてください

```
It is possible to change it from the command line, but it is safer to change it from P4V
Try to change both the P4CHARSET and client character encoding
```

# P4CHARSETを変更する


![文字コード変更1](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/p4v.image.01.png)

![文字コード変更2](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/p4v.image.02.png)

ここから変更  

```
Change from here
```

# クライアントの文字エンコーディングを変更する

![文字コード変更1](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/p4v.image.03.png)

![文字コード変更2](https://raw.githubusercontent.com/hexagrimoire/hexagrimoire.github.io/main/static/wiki/image/03_HelixCore/p4v.image.04.png)

ここから変更  

```
Change from here
```

サーバー側と異なる文字エンコードが設定されている場合は  
動作で不具合が生じる可能性があります。

適切な文字エンコードに変更してください

```
If the server side and the character encoding is set differently, the
There may be glitches in operation, such as logging.

Please change to the proper character encoding
```