FROM sameersbn/redmine:4.1.1
LABEL maintainer "ueno.s <ueno.s@gamestudio.co.jp>"

ENV REDMINE_DATA_VOLUME_HOME /home/redmine/data/certs
RUN mkdir -p ${REDMINE_DATA_VOLUME_HOME}
RUN openssl genrsa -out "$REDMINE_DATA_VOLUME_HOME/redmine.key" 4096
RUN openssl req -new -key "$REDMINE_DATA_VOLUME_HOME/redmine.key" -out "$REDMINE_DATA_VOLUME_HOME/redmine.csr" -subj "/O=GameStudio Inc./CN=www.gamestudio.co.jp"
RUN openssl x509 -req -days 3560 -in "$REDMINE_DATA_VOLUME_HOME/redmine.csr" -signkey "$REDMINE_DATA_VOLUME_HOME/redmine.key" -out "$REDMINE_DATA_VOLUME_HOME/redmine.crt"
