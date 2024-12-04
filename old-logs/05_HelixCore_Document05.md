# HelixCore AuthenticationExtension

# HelixCore Serverをインストールする

[HelixCore Server](03_HelixCore_Document02)

# AuthenticationExtension のプラグインを追加

gitのリポジトリを適当な位置にコピー

```
git clone https://github.com/perforce/helix-authentication-extension.git /opt/helix-authentication-extension
```



```
\cp -f client.crt /opt/helix-authentication-extension/loginhook/client.crt
\cp -f client.key /opt/helix-authentication-extension/loginhook/client.key
\cp -f ca.crt /opt/helix-authentication-extension/loginhook/ca.crt
```


```
cd /opt/helix-authentication-extension
p4 extension --package loginhook
p4 extension --install loginhook.p4-extension -y
```

```
p4 admin restart
```

```
p4 extension --configure Auth::loginhook -o > global_config.txt
```


```
ExtP4USER: super
```

```
ExtConfig:
     Auth-Protocol:
             saml
     Service-URL:
             https://auth-svc.example.com:3000/
```

```
p4 extension --configure Auth::loginhook -i < global_config.txt
```

```
p4 extension --configure Auth::loginhook --name loginhook-a1 -o > instance_config.txt
```

```
ExtConfig:
        enable-logging:
                true
        name-identifier:
                nameID
        non-sso-groups:
                admins
        non-sso-users:
                super
        user-identifier:
                email
```

```
p4 extension --configure Auth::loginhook --name loginhook-a1 -i < instance_config.txt
```

```
p4 configure set security=3
p4 configure set auth.sso.allow.passwd=1
```


※ここの元記事  
[@p4misc](https://twitter.com/p4misc)  
https://github.com/p4misc/p4memo/blob/master/helix-authentication-service.md  
