FROM php:7.2-cli-alpine as build
RUN sed -i "s/dl-cdn.alpinelinux.org/mirror.tuna.tsinghua.edu.cn/" /etc/apk/repositories
# PHP redis扩展编译
RUN set -xe \
    && apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libxml2-dev libwebp-dev gettext-dev argon2-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/ \
    && docker-php-ext-install gd zip bcmath pdo_mysql calendar exif gettext mysqli pcntl shmop sockets standard sysvmsg sysvsem sysvshm opcache

FROM php:7.2-fpm-alpine

LABEL MAINTAINER maowei <maowei@hoge.cn>

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

RUN sed -i "s/dl-cdn.alpinelinux.org/mirror.tuna.tsinghua.edu.cn/" /etc/apk/repositories

# COPY build 阶段编译的php扩展
COPY --from=build /usr/local/lib/php/extensions/no-debug-non-zts-20170718/ /usr/local/lib/php/extensions/no-debug-non-zts-20170718/
RUN set -xe \
    && apk add --no-cache freetype libjpeg-turbo libpng libxml2 libwebp gettext argon2 \
    && docker-php-ext-enable gd zip bcmath pdo_mysql 

# 安装 composer
RUN set -xe \
    && php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && rm -f composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

# 安装项目依赖
RUN set -xe \
    && apk add --no-cache nginx redis supervisor \
    && mkdir -p /etc/supervisor/conf.d
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/env.conf /etc/supervisor/conf.d/env.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sample.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# 复制项目代码
COPY html/ /var/www/html/

# 清理
RUN set -xe \
    && docker-php-source delete

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]
