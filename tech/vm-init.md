# VMを適当に作りたい人向けのmemo

```
sudo apt update
sudo apt upgrade -y
sudo apt install vim
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
sudo update-alternatives --set editor /usr/bin/vim.basic
sudo reboot
```

```
ssh-keygen -t ed25519 -C "dosukebe-key"

// 作成された鍵ファイルをauthorized_keysに名前変更
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```
これでログインできるかを確認する
~/.ssh/id_ed25519　を　手元に持ってくる。

```
vim /etc/ssh/sshd_config
```

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
X11Forwarding no
```
sudo systemctl restart sshd

```
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

```
sudo apt install ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp

sudo ufw enable
sudo ufw status
```

```
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```
