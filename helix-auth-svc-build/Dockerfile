FROM ubuntu:focal
LABEL maintainer "ueno.s <ueno.s@gamestudio.co.jp>"

ENV container docker

ARG USER=perforce
ARG PASSWD=perforce

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN apt-get update -y \
    && apt-get install -y wget gnupg less language-pack-ja-base language-pack-ja tzdata curl jq git openssl sudo vim wget unzip cron logrotate init systemd

RUN echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc ;\
    echo 'export LANGUAGE="ja_JP:ja"' >> ~/.bashrc

RUN wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add - ;\
    echo "deb http://package.perforce.com/apt/ubuntu focal release" >> /etc/apt/sources.list.d/perforce.list

RUN apt-get update && apt-get -y install helix-p4d helix-proxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# See: https://hub.docker.com/_/centos/
RUN echo "$USER:$PASSWD" | chpasswd \
    && echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


# Add external files
COPY files/run.sh /usr/local/bin/run.sh
COPY files/p4p /etc/logrotate.d/p4p

RUN chmod +x /usr/local/bin/run.sh

# --------------------------------------------------------------------------------
# P4P ENVIRONMENT
# --------------------------------------------------------------------------------
ARG P4HOME=/opt/perforce/servers
ARG P4PLOGDIR=${P4HOME}/log

ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8" \
    P4PCACHE=${P4HOME}/p4p-master \
    P4SSLDIR=${P4HOME}/ssl \
    P4PLOGFILE=${P4PLOGDIR}/p4p.log

RUN sudo -E -u perforce mkdir -p ${P4PCACHE} \
    && sudo -E -u perforce mkdir -p ${P4SSLDIR} \
    && sudo -E -u perforce mkdir -p ${P4PLOGDIR} \
    && sudo -E -u perforce chmod 700 ${P4SSLDIR} \
    && chmod 644 /etc/logrotate.d/p4p \
    && /usr/sbin/logrotate /etc/logrotate.conf

EXPOSE 1777

HEALTHCHECK \
    --interval=2m \
    --timeout=30s \
    CMD p4 -p ssl:1777 info -s > /dev/null || exit 1

CMD ["/sbin/init"]
