# docker-machineの鍵を入れ替える

## 期限を確認する

```
openssl x509 -in .machine/certs/cert.pem -noout -dates
# openssl x509 -in <KEY-FILE> -noout -dates
```

```
notBefore=Apr  1 01:07:00 2021 GMT
notAfter=Mar 16 01:07:00 2024 GMT
```

## 鍵を入れ替える

```
docker-machine regenerate-certs --client-certs <DOCKER-MACHINE>
```
* dockerが再起動になる
* 自動でアップデートコマンドが走る
* 起動オプションが変わる可能性がある