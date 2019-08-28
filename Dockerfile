FROM ubuntu:18.04
MAINTAINER Kimtaek <jinze1991@icloud.com>

RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y locales tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8

ENV DEBCONF_NOWARNINGS yes
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Seoul

RUN ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install "software-properties-common" (for the "add-apt-repository")
RUN apt -y install software-properties-common

# Add the "PHP 7" ppa
RUN add-apt-repository ppa:ondrej/php
RUN add-apt-repository ppa:ondrej/nginx

# Install Nginx, Supervisor and some useful Tools
RUN apt install -y \
    nginx \
    supervisor \
    dialog \
    git \
    cron \
    curl \
    vim

# Install PHP-CLI 7, some PHP extentions
RUN rm -Rf /etc/php/*
RUN apt install -y \
    php7.0 \
    php7.0-fpm \
    php7.0-cli \
    php7.0-common \
    php7.0-bcmath \
    php7.0-mbstring \
    php7.0-soap \
    php7.0-xml \
    php7.0-zip \
    php7.0-apcu \
    php7.0-json \
    php7.0-gd \
    php7.0-curl \
    php7.0-mysql \
    php7.0-imap \
    php7.0-mcrypt \
    php7.0-tidy

RUN rm -rf /etc/php/5.6 /etc/php/7.1 /etc/php/7.2 /etc/php/7.3
RUN apt clean

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Configure Supervisor, Mariadb configs
ADD startup.sh /opt/bin/startup.sh
RUN chmod u=rwx /opt/bin/startup.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configure php.ini
RUN sed -ri "s/post_max_size = 8M/post_max_size = 128M/g" /etc/php/7.0/fpm/php.ini
RUN sed -ri "s/upload_max_filesize = 2M/upload_max_filesize = 32M/g" /etc/php/7.0/fpm/php.ini
RUN sed -ri "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/7.0/fpm/php.ini

# Configure opcache.ini
RUN echo 'opcache.enable=1 \n\
opcache.memory_consumption=512 \n\
opcache.interned_strings_buffer=16 \n\
opcache.max_accelerated_files=32531 \n\
opcache.validate_timestamps=0 \n\
opcache.save_comments=1 \n\
opcache.fast_shutdown=0' >> /etc/php/7.0/fpm/conf.d/10-opcache.ini

# Configure php-fpm.ini
# RUN echo '; Custom configs, recommend for over 8G memory\n\
# pm=static \n\
# pm.max_children=300 \n\
# pm.start_servers=20 \n\
# pm.min_spare_servers=5 \n\
# pm.max_spare_servers=30 \n\
# pm.max_requests=10240 \n\
# request_terminate_timeout=30' >> /etc/php/7.0/fpm/php-fpm.conf

# Configure php-fpm.ini
RUN echo '; Custom configs, recommend for under 8G memory \n\
pm=dynamic \n\
pm.max_children=50 \n\
pm.start_servers=20 \n\
pm.min_spare_servers=10 \n\
pm.max_spare_servers=30 \n\
pm.max_requests=10240 \n\
request_terminate_timeout=30' >> /etc/php/7.0/fpm/php-fpm.conf

EXPOSE 80 443
WORKDIR /www
ENTRYPOINT ["/opt/bin/startup.sh"]