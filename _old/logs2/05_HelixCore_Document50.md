# AzureADとHASを繋ぐ為のメモ

https://github.com/p4misc/p4memo/blob/master/helix-authentication-service.md  
https://github.com/perforce/helix-authentication-extension  
https://github.com/perforce/helix-authentication-service  

---
鍵コピー用コマンド

```
docker cp helixcore_helixcore_1:/opt/helix-authentication-extension/loginhook/ca.crt ca.crt
docker cp helixcore_helixcore_1:/opt/helix-authentication-extension/loginhook/client.crt client.crt
docker cp helixcore_helixcore_1:/opt/helix-authentication-extension/loginhook/client.key client.key

docker cp ca.crt helix-auth_auth_1:/opt/helix-authentication-service/certs/ca.crt
docker cp client.crt helix-auth_auth_1:/opt/helix-authentication-service/certs/client.crt
docker cp client.key helix-auth_auth_1:/opt/helix-authentication-service/certs/client.key

```