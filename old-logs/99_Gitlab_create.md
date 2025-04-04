# docker-compose.yml

```
version: '3'

networks:
  default:
    external:
      name: common

volumes:
  config: # GitLab config
  logs:   # GitLab logs
  data:   # GitLab main data

services:
  gitlab:
    container_name: gitlab-develop
    image: 'gitlab/gitlab-ce:16.6.0-ce.0'
    ports:
      - '3080:3080' # http
      - '3022:3022' # ssh
    volumes:
      - 'config:/etc/gitlab'
      - 'logs:/var/log/gitlab'
      - 'data:/var/opt/gitlab'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://127.0.0.1:3080'
        gitlab_rails['time_zone'] = 'Asia/Tokyo'
        gitlab_rails['gitlab_shell_ssh_port'] = 3022
        gitlab_rails['lfs_enabled'] = true

```


# 管理者アカウントパスワード

メールアドレス：
admin@example.com

パスワード：
ここを開く

```
cat /etc/gitlab/initial_root_password
```