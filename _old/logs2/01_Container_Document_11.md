# https-portalについて

結構使えそうなのでメモ

* (公式) Github  
https://github.com/SteveLTN/https-portal

* (Qiita)主な参考元記事  
[docker で全自動 Let's encrypt](https://qiita.com/kuboon/items/f424b84c718619460c6f)  
[https-portalを使ってみて、個人的にぶつかりそうな壁の解決方法](https://qiita.com/github0013@github/items/71c44d7bf4faf63c1956)

---

# 使い方（sample）

## docker-composeに追加する

```
  https-portal:
    image: steveltn/https-portal:1
    ports:
      - 80:80
      - 443:443
    environment:
      # Redirect my.example.com to https:://letsencrypt.org
      # The upsteams will be available as <%= domain.upstream %> in Nginx config
      DOMAINS: 'ZZZZZZZZZZZZZZZZZZZZ -> http://XXXXXXXXXXXXXXXX:port'
      STAGE: local
    volumes:
      - https-portal_data:/var/lib/https-portal

```

Volumeデータを作成
```
volumes:
  https-portal_data:
```

## 失敗とか

* https-portalの中身はポート転送なので、  
アプリケーション側にhttp⇒httpsポート転送ができる場合は切っておく  