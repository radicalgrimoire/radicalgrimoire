# CentOS8 → CentOS Stream

> https://centos.org/distro-faq/#q7-how-do-i-migrate-my-centos-linux-8-installation-to-centos-stream

```
dnf install centos-release-stream
dnf swap centos-{linux,stream}-repos
dnf distro-sync
cat /etc/centos-release
```