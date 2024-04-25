FROM ubuntu:focal
LABEL maintainer="ueno.s <ueno.s@gamestudio.co.jp>"

COPY files/run.sh /usr/local/bin/run.sh
COPY files/log.sh /usr/local/bin/log.sh
COPY files/p4p /etc/logrotate.d/p4p

ARG USER=perforce
ARG PASSWD=perforce
ARG P4HOME=/opt/perforce/servers
ARG P4PLOGDIR=${P4HOME}/log

ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8" \
    P4PCACHE=${P4HOME}/p4p-master \
    P4SSLDIR=${P4HOME}/ssl \
    P4PLOGFILE=${P4PLOGDIR}/p4p.log

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apt-get update -y \
    && apt-get install -y wget gnupg less language-pack-ja-base language-pack-ja tzdata curl jq git openssl sudo vim unzip cron logrotate init systemd \
    && wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add - \
    && echo "deb http://package.perforce.com/apt/ubuntu focal release" >> /etc/apt/sources.list.d/perforce.list \
    && apt-get update -y \
    && apt-get install -y helix-p4d helix-proxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc \
    && echo 'export LANGUAGE="ja_JP:ja"' >> ~/.bashrc \
    && echo "$USER:$PASSWD" | chpasswd \
    && echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && chmod +x /usr/local/bin/run.sh \
    && chmod +x /usr/local/bin/log.sh \
    && sudo -E -u perforce mkdir -p ${P4PCACHE} ${P4SSLDIR} ${P4PLOGDIR} \
    && sudo -E -u perforce chmod 700 ${P4SSLDIR} \
    && chmod 644 /etc/logrotate.d/p4p \
    && sudo -E -u perforce p4d -Gc \
    && sudo -E -u perforce p4d -Gf \
    && echo ' ' > ${P4PLOGFILE} \
    && chown perforce:perforce ${P4PLOGFILE}


EXPOSE 1777

HEALTHCHECK --interval=2m --timeout=30s CMD p4 -p ssl:1777 info -s > /dev/null || exit 1

CMD ["/usr/local/bin/log.sh"]