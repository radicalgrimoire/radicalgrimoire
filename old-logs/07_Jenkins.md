https://www.hiroom2.com/2017/12/19/docker-jenkins-ja/

```
https://jenkins.io/  
https://developer.github.com/v3/guides/managing-deploy-keys/ 
https://qiita.com/yuch_i/items/44d224112382b5f1c8eb
```

# OpenJDKのインストール

```
$ sudo yum install java-1.8.0-openjdk
$ sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
$ sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
$ sudo yum install jenkins
$ vi /etc/sysconfig/jenkins
-----
JENKINS_PORT="8082"
-----
// サービススタート
$ sudo service jenkins start
$ sudo chkconfig jenkins on

```


初期パスワードはここ

```
$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

# 画面が真っ白になる

https://qiita.com/ogataka50/items/c37d0e690dc6cd108e60

```
#JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true"
tmpdir="/var/cache/jenkins/war"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djava.io.tmpdir=${tmpdir}"
```

##### 元記事

https://qiita.com/inakadegaebal/items/b526ffbdbe7ff2b443f1