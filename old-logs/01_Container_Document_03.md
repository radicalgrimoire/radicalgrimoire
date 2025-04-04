Docker: LinuxマシンにDockerをインストールする
====

## 0. 概要
- LinuxマシンにDockerをインストールする方法がいくつかありますが、その中でも比較的簡単な方法である、docker-machineを使用した方法を紹介します。docker-machineのgenericドライバを使用して、既存のLinuxマシンに対して透過的にdockerをインストールできます。ここではLinuxディストロにCentOS7を採用しますが、他のディストロでも同様にできます。

### 0-1. 登場するマシン

- dockerホスト
  - 今回Docker(daemon)をインストールする対象のホストマシンです。
  - LinuxディストリビューションにCentOS7を採用します。
  - ユーザdocker/グループdockerが存在します。

- docker-machineホスト
  - docker-machineコマンドを実行するホストマシンです。
  - docker-machineを使う場合にはdockerのクライアントにもなります。
  - dockerホストにユーザdockerでssh接続します。
  - 通常、主な作業マシンがこれになります。Windowsでも可能です。


  > [docker-machineホスト]--(ssh)-->[dockerホスト]

## 1. CentOS7のインストール

- CentOS7のインストールの具体的な手順は割愛しますが、要件は以下の通りです。
    - インストーラで[最低限のインストール(minimum)]を選択する。
    - ユーザrootに対してsshログインできるようにする。

## 2. ユーザdockerの作成と設定
- rootでsshログインします。
- visudoコマンドを実行して以下の行を確認します。
  ```
  # visudo
  ```
  - 下記の行のコメントアウトを外す。wheelグループに属するユーザはすべてのコマンドを実行できるようにします。
  ```
  ## Allows people in group wheel to run all commands
  %wheel  ALL=(ALL)       ALL
  ```
  - 以下の行のコメントアウトを外す。sudoをパスワードなしで実行できるようにします。
  ```
  # Same thing without a password
  %wheel        ALL=(ALL)       NOPASSWD: ALL
  ```
  
- ユーザdockerを追加します。
  ```
  # useradd docker
  ```
  - (optional)すでにグループdockerが存在する、というエラーが発生した場合は、グループdockerにユーザdockerを追加します。
  ```
  # useradd -g docker docker
  ```
  - (optional)ユーザdockerの情報を確認します。
  ```
  # id -a docker
  ```

- ユーザdockerの設定をします。
  - ユーザdockerのパスワードを設定します。
  ```
  # passwd docker
  ```
  - ユーザdockerをwheelグループに追加します。
  ```
  # usermod -aG wheel docker
  ```
  - (optional)wheelグループを確認します。
  ```
  # cat /etc/group
  ```
  
- (注意)dockerというユーザ名およびグループ名は重要です。理由は、docker daemonの実行権がグループdockerに属するユーザにあり、ユーザdockerは初めからグループdockerに属するからです。ほかのユーザ名にしたい場合はグループdockerを作成し、そこにユーザを追加してください。

## 3. SSH設定
- (@docker-machineホスト) SSH鍵を作成します。(すでにdocker用のSSH鍵が存在する場合は不要です。)
    ```
    $ ssh-keygen
    ```
- (@docker-machineホスト) 上記で作成した鍵のうち、公開鍵の内容をdockerホスト側に送ります。scpでdockerホストにファイルごと送るか、公開鍵の内容をクリップボードにコピーしてください。
    ```
    $ scp ~/.ssh/id_rsa.pub username@hostname:/tmp
    ```

- (@dockerホスト) ユーザdockerでログインして、~/.ssh/authorized_keyに追記します。
    - ~/.sshフォルダが存在しない場合は作成します。
    ```
    $ mkdir ~/.ssh
    ```
    - ~/.ssh/authorized_keys に公開鍵を追記します。クリップボードにコピーした場合はviでauthorized_keysを開いてペーストします。
    ```
    $ cat /tmp/id_rsa.pub >> ~/.ssh/authorized_keys
    ```
    - 所有者以外のアクセスを許可しないようにします。
    ```
    $ chmod 700 ~/.ssh/
    $ chmod 600 ~/.ssh/authorized_keys
    ```
  
- (optional)(@docker-machineホスト) ユーザdockerでssh接続できるかどうかは、クライアント側で以下のコマンドを試す。
  ```
  $ ssh -i ~/.ssh/id_rsa docker@hostname
  ```

## 4. docker-machineでdockerをインストール
- (@dockerホスト) net-toolsをインストールします。centos7ではnetstatが非推奨ですが、docker-machineでnetstatを使用しているため。
  ```
  # yum install -y net-tools
  ```
  - インストールしないと、以降に実行する`docker-machine`コマンドで以下のようなエラーが発生します。
  ```
  Error running SSH command: something went wrong running an SSH command
  command : if ! type netstat 1>/dev/null; then ss -tln; else netstat -tln; fi
  err     : exit status 127
  output  : bash: line 0: type: netstat: not found
  bash: ss: command not found
  ```

- (@dockerホスト) port2376を開放します。開放しなければdocker-machineで接続できません。
  ```
  # firewall-cmd --add-port=2376/tcp --zone=public --permanent
  ```
  - ファイアウォールをリロードします。
  ```
  # firewall-cmd --reload
  ```
  - (optional) 設定したポートが解放されていることを確認します。
  ```
  # firewall-cmd --list-ports --zone=public
  ```

- (@docker-machineホスト) git bashで以下のようなコマンドを実行する。
  ```
  $ docker-machine create -d generic \
    --generic-ip-address ${TARGET_IPADDR} \
    --generic-ssh-user docker \
    --generic-ssh-key ~/.ssh/docker/id_rsa \
    ${NODE_NAME}
  ```
    - (optional) 以下のようなssh鍵が見つからないエラーが発生することがある。その場合は、`--generic-ssh-key`の値を以下のようなWindows形式のフルパスにする。(区切り文字は普通のスラッシュとする。)
    ```
    Error with pre-create check: "SSH key does not exist: \"/c/Users/shimada.r/.ssh/docker/id_rsa\""
    ```
    ```
    --generic-ssh-key C:/Users/shimada.r/.ssh/docker/id_rsa
    ```
    - (optional) 以下ような証明書に関するエラーが発生することがある。
    ```
    Checking connection to Docker...
    Error creating machine: Error checking the host: Error checking and/or regenerating the certs: There was an error validating certificates for host "172.20.16.134:2376": dial tcp 172.20.16.134:2376: i/o timeout
    You can attempt to regenerate them using 'docker-machine regenerate-certs [name]'.
    Be advised that this will trigger a Docker daemon restart which might stop running containers.
    ```
    その場合は、証明書を再発行して、
    ```
    $ docker-machine regenerate-certs ${NODE_NAME}
    ```
    dockerマシンを再起動する。
    ```
    $ docker-machine restart ${NODE_NAME}
    ```
    このとき、以下のようなエラーが出ることがあるが、再起動によりssh接続が切断されただけなので気にしない。
    ```
    ssh command error:
    command : sudo shutdown -r now
    err     : exit status 255
    output  : Connection to 172.20.16.134 closed by remote host.
    ```
- (@docker-machineホスト) docker-machine経由でdockerコマンドを実行できることを確認する。
  ```
  $ eval $(docker-machine env ${NODE_NAME})
  $ docker ps
  ```

## 参考文献
- 【公式】Get Docker CE for CentOS
  - https://docs.docker.com/install/linux/docker-ce/centos/

(以上)
