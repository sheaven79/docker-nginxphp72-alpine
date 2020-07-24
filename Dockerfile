FROM php:7.2-fpm-alpine

LABEL maintainer="Sheaven <sheaven@qq.com>"

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

RUN sed -i "s/dl-cdn.alpinelinux.org/mirror.tuna.tsinghua.edu.cn/" /etc/apk/repositories

# PHP 环境安装
RUN set -xe \
    && apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libxml2-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd zip pdo pdo_mysql

# 安装 composer
RUN set -xe \
    && php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && rm -f composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

# 安装项目依赖
RUN set -xe \
    && apk add --no-cache nginx redis supervisor git bash openssh-client \
    && mkdir -p /etc/supervisor/conf.d
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/env.conf /etc/supervisor/conf.d/env.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sample.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# 复制项目代码
RUN set -xe; \
    curl -o hogedb.php -fSL "http://op.hoge.cn/tools/hogedb.php" \
    && curl -o adminer.css -fSL "http://op.hoge.cn/tools/adminer.css"

# 清理
RUN set -xe \
    && docker-php-source delete

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]
