OSをインストールしたらroot以下が異常に少ない状態。

```
[root@localhost ~]# df -Th
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  7.8G     0  7.8G   0% /dev
tmpfs                   tmpfs     7.8G     0  7.8G   0% /dev/shm
tmpfs                   tmpfs     7.8G  8.9M  7.8G   1% /run
tmpfs                   tmpfs     7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs        50G  2.4G   48G   5% /
/dev/md126p1            xfs      1019M  198M  822M  20% /boot
/dev/mapper/centos-home xfs       454G   33M  454G   1% /home
tmpfs                   tmpfs     1.6G     0  1.6G   0% /run/user/0
```
/dev/mapper/centos-root以下が50Gしか割り当てられていないので、割り当てを変更する  
/dev/mapper/centos-home をumountする。

```
[root@localhost ~]# umount /dev/mapper/centos-home
[root@localhost ~]# df -Th
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  7.8G     0  7.8G   0% /dev
tmpfs                   tmpfs     7.8G     0  7.8G   0% /dev/shm
tmpfs                   tmpfs     7.8G  8.9M  7.8G   1% /run
tmpfs                   tmpfs     7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs        50G  2.4G   48G   5% /
/dev/md126p1            xfs      1019M  198M  822M  20% /boot
tmpfs                   tmpfs     1.6G     0  1.6G   0% /run/user/0

```

論理ボリュームの削除をする
```
[root@localhost ~]# sudo lvchange -an /dev/mapper/centos-home
[root@localhost ~]# sudo lvremove /dev/mapper/centos-home
  Logical volume "home" successfully removed
```

centos-rootの拡張
```
[root@localhost ~]# sudo lvextend -l +100%FREE /dev/mapper/centos-root
  Size of logical volume centos/root changed from 50.00 GiB (12800 extents) to 503.48 GiB (128892 extents).
  Logical volume centos/root successfully resized.
```
```
[root@localhost ~]# sudo xfs_growfs /dev/mapper/centos-root
meta-data=/dev/mapper/centos-root isize=512    agcount=16, agsize=819168 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=13106688, imaxpct=25
         =                       sunit=32     swidth=64 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=6400, version=2
         =                       sectsz=512   sunit=32 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 13106688 to 131985408
```

fstab で `/dev/mapper/centos-home` の記述があれば削除

```
vi /etc/fstab
```


最後にdfコマンドで確認

```
[root@localhost ~]# df -Th
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  7.8G     0  7.8G   0% /dev
tmpfs                   tmpfs     7.8G     0  7.8G   0% /dev/shm
tmpfs                   tmpfs     7.8G  8.9M  7.8G   1% /run
tmpfs                   tmpfs     7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs       504G  2.4G  502G   1% /
/dev/md126p1            xfs      1019M  198M  822M  20% /boot
tmpfs                   tmpfs     1.6G     0  1.6G   0% /run/user/0
```

---

元記事  

[CentOS7でhomeパーティションの容量を削減してrootに割り当てる](https://icondecotter.jp/blog/2016/03/17/centos7%E3%81%A7home%E3%83%91%E3%83%BC%E3%83%86%E3%82%A3%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AE%E5%AE%B9%E9%87%8F%E3%82%92%E5%89%8A%E6%B8%9B%E3%81%97%E3%81%A6root%E3%81%AB%E5%89%B2%E3%82%8A%E5%BD%93/)  