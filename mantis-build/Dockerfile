FROM alpine:3.14
WORKDIR /
RUN  apk update \
  && apk add --no-cache apache2 php8-apache2 php8-mysqli php8-pdo php8-pdo_mysql php8-intl php8-mbstring php8-session php8-curl php8-json php8-xml php8-zip php8-tokenizer php8-ctype php8-gd php8-xmlwriter php8-xmlreader php8-dom php8-zlib php8-iconv php8-simplexml php8-fileinfo openssl openrc unzip git \
  && rm -rf /var/cache/apk/* \
  && wget https://sourceforge.net/projects/mantisbt/files/mantis-stable/2.25.7/mantisbt-2.25.7.tar.gz \
  && tar xvfz mantisbt-2.25.7.tar.gz \
  && rm -f mantisbt-2.25.7.tar.gz \
  && mkdir -p /opt \
  && mv mantisbt-2.25.7 /opt/mantisbt \
  && chown -R apache:apache /opt/mantisbt \
  && ln -s  /opt/mantisbt /var/www/localhost/htdocs \
  && mkdir -p /run/apache2 \
  && mkdir -p /var/mantisbt \
  && chown -R apache:apache /var/mantisbt

EXPOSE 80

VOLUME ["/var/mantisbt","/opt/mantisbt"]

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
