FROM ubuntu:16.04
MAINTAINER Kimtaek <jinze1991@icloud.com>

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8

ENV DEBCONF_NOWARNINGS=yes \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Seoul \
    MYSQL_USER=root \
    MYSQL_VERSION=5.7.26 \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql

RUN ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Install PHP-CLI 7, some PHP extentions and some useful Tools with APT
RUN apt-get update
RUN apt-get install -y \
        mariadb-server \
        php7.0 \
        php7.0-fpm \
        php7.0-cli \
        php7.0-common \
        php7.0-bcmath \
        php7.0-mbstring \
        php7.0-soap \
        php7.0-xml \
        php7.0-zip \
        php7.0-json \
        php7.0-gd \
        php7.0-curl \
        php7.0-mysql \
        php7.0-imap \
        php7.0-tidy \
        php7.0-mcrypt \
        php-xdebug \
        cron \
        curl \
        supervisor \
        nginx \
        vim

RUN rm -rf /etc/php/5.6 /etc/php/7.1 /etc/php/7.2 ${MYSQL_DATA_DIR} /var/lib/apt/lists/*
RUN apt-get clean

RUN sed -e '29d' < /etc/mysql/mariadb.conf.d/50-server.cnf >> /etc/mysql/mariadb.conf.d/server.cnf
RUN rm -rf /etc/mysql/mariadb.conf.d/50-server.cnf

# Php.ini
RUN sed -ri "s/post_max_size = 8M/post_max_size = 128M/g" /etc/php/7.0/fpm/php.ini
RUN sed -ri "s/upload_max_filesize = 2M/upload_max_filesize = 32M/g" /etc/php/7.0/fpm/php.ini
RUN sed -ri "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/7.0/fpm/php.ini

# php-fpm.ini
# RUN echo '; Custom configs, recommend for over 8G memory\n\
# pm=static \n\
# pm.max_children=300 \n\
# pm.start_servers=20 \n\
# pm.min_spare_servers=5 \n\
# pm.max_spare_servers=30 \n\
# pm.max_requests=10240 \n\
# request_terminate_timeout=30' >> /etc/php/7.0/fpm/php-fpm.conf

# php-fpm.ini
RUN echo '; Custom configs, recommend for under 8G memory \n\
pm=dynamic \n\
pm.max_children=50 \n\
pm.start_servers=20 \n\
pm.min_spare_servers=10 \n\
pm.max_spare_servers=30 \n\
pm.max_requests=10240 \n\
request_terminate_timeout=30' >> /etc/php/7.0/fpm/php-fpm.conf

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/bin/startup.sh
RUN chmod u=rwx /opt/bin/startup.sh

WORKDIR /www
EXPOSE 80 443 3306 9001

ENTRYPOINT ["/opt/bin/startup.sh"]
