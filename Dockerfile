# 预编译PHP扩展阶段
FROM php:7.2-fpm-alpine as build
# PHP 扩展编译
RUN set -xe \
    && apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libxml2-dev libwebp-dev gettext-dev argon2-dev libxml2-dev libxslt-dev zlib-dev imagemagick-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/ \
    && docker-php-ext-install gd zip bcmath pdo_mysql calendar exif gettext mysqli pcntl shmop sockets sysvmsg sysvsem sysvshm wddx xsl\
    && apk add --no-cache autoconf ${PHPIZE_DEPS}
RUN set -xe \
    && pecl install redis-5.3.1.tgz \
    && pecl install mongodb-1.8.0.tgz \
    && pecl install swoole-4.5.2.tgz \
    && pecl install xlswriter-1.3.6.tgz \
    && pecl install xhprof-2.2.0.tgz \
    && pecl install imagick-3.4.4.tgz

# 正式阶段
FROM php:7.2-fpm-alpine
LABEL MAINTAINER maowei <sheaven@qq.com>

RUN mkdir -p /var/www/html
WORKDIR /var/www/html
# 替换国内系统镜像源
RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories
# 安装依赖包
RUN set -xe \
    && apk add --no-cache freetype libjpeg-turbo libpng libzip libxml2 libwebp gettext argon2 libxslt libstdc++ zlib curl imagemagick
# COPY build 阶段编译的 PHP 扩展
COPY --from=build /usr/local/lib/php/extensions/no-debug-non-zts-20170718/ /usr/local/lib/php/extensions/no-debug-non-zts-20170718/
COPY --from=build /usr/local/include/php/ext/swoole/ /usr/local/include/php/ext/swoole/
COPY --from=build /usr/local/include/php/ext/imagick/ /usr/local/include/php/ext/imagick/
# 启用 PHP 扩展
RUN set -xe \
    && docker-php-ext-enable gd zip bcmath pdo_mysql calendar exif gettext mysqli pcntl shmop sockets sysvmsg sysvsem sysvshm wddx xsl opcache redis mongodb swoole xlswriter xhprof imagick

# 安装 composer
RUN set -xe \
    && curl -o /usr/local/bin/composer -fSL "https://mirrors.aliyun.com/composer/composer.phar" \
    && chmod +x /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 安装项目依赖
RUN set -xe \
    && apk add --no-cache nginx supervisor \
    && mkdir -p /etc/supervisor/conf.d
COPY etc/zoneinfo_Shanghai /etc/localtime
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/env.conf /etc/supervisor/conf.d/env.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sample.conf /etc/nginx/conf.d/default.conf
COPY php/php-fpm.d /usr/local/etc/php-fpm.d
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# 复制项目代码
COPY html/ /var/www/html/

# 清理
RUN set -xe \
    && docker-php-source delete

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]
