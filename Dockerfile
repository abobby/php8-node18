FROM ubuntu:jammy
# MAINTAINER Subhasish Ghosh, subhasishghosh@gmail.com

RUN apt update
RUN apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common

# Install Apache2
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install apache2

# Set apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Set Timezone 
ENV TZ=Asia/Calcutta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Additional Packages
RUN apt-get install -y libmcrypt-dev openssl curl git wget libssl-dev autoconf g++ make pkg-config \
    vim zip unzip

# Install PHP 8.2
RUN add-apt-repository -y ppa:ondrej/php
RUN apt install -y php8.2-common php8.2-cli

# Install PHP 7.2 and PHP Extensions
RUN apt-get install -y libapache2-mod-php8.2 php8.2 php8.2-cli php8.2-xdebug php8.2-mbstring php8.2-mysql php8.2-imagick \
    php8.2-memcached php-pear imagemagick php8.2-dev php8.2-gd php8.2-curl php8.2-intl php8.2-mongodb php8.2-zip \
    php8.2-xml

# Install Composer
RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
RUN HASH=`curl -sS https://composer.github.io/installer.sig`
RUN echo $HASH
RUN php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Set Apache VirtualHost
RUN cd /etc/apache2/sites-available && a2ensite 000-default.conf && service apache2 restart

# Enable apache mods
RUN a2enmod rewrite

# Update php.ini file, enable short tags <? ?> and error logging.
#RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.2/apache2/php.ini
#RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.2/apache2/php.ini

VOLUME ["/var/www/html"]
WORKDIR /var/www/html

EXPOSE 80

# Installing NodeJs
RUN mkdir /var/www/ui
RUN cd ~
RUN curl -sL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt install nodejs


# Copy this repo into place.
# ADD src/www /var/www/html

# Update the default apache site with the config we created.
# ADD config/vhost.conf /etc/apache2/sites-enabled/000-default.conf

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND

# CMD ["cd /var/www/html && composer install && cp .env.example .env && php artisan key:generate"]
# RUN cd /var/www/html && composer install && cp .env.example .env && php artisan key:generate
