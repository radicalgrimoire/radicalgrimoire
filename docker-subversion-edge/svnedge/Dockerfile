FROM mamohr/subversion-edge:latest
LABEL maintainer "ueno.s <ueno.s@gamestudio.co.jp>"
ENV container docker

RUN yum install -y tzdata

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"
