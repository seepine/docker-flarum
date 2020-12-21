FROM alpine:3.12

LABEL description="Simple forum software for building great communities" \
      maintainer="Magicalex <magicalex@mondedie.fr>, Hardware <hardware@mondedie.fr>"

ARG VERSION=v0.1.0-beta.14

ENV GID=991 \
    UID=991 \
    UPLOAD_MAX_SIZE=50M \
    PHP_MEMORY_LIMIT=128M \
    OPCACHE_MEMORY_LIMIT=128 \
    DB_HOST=mariadb \
    DB_USER=flarum \
    DB_NAME=flarum \
    DB_PORT=3306 \
    FLARUM_TITLE=Docker-Flarum \
    DEBUG=false \
    LOG_TO_STDOUT=false \
    GITHUB_TOKEN_AUTH=false \
    FLARUM_PORT=8888
# 配置apk国内源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装基础环境
RUN apk add --no-progress --no-cache \
    curl \
    git \
    libcap \
    nginx \
    php7 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-exif \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-gmp \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-mysqlnd \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-phar \
    php7-session \
    php7-tokenizer \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
    su-exec \
    s6

# 安装composer及配置国内源
RUN  cd /tmp \
  && curl -s https://install.phpcomposer.com/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && sed -i 's/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/' /etc/php7/php.ini \
  && chmod +x /usr/local/bin/composer \
  && composer selfupdate \
  && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 安装flarum
RUN  mkdir -p /flarum/app \
  && COMPOSER_CACHE_DIR="/tmp" composer create-project --stability=beta --no-progress -- flarum/flarum /flarum/app $VERSION \
  && composer clear-cache \
  && rm -rf /flarum/.composer /tmp/* \
  && setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/nginx

COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/*

VOLUME /flarum/app/extensions /etc/nginx/conf.d

# 依次是简体，日语，中文搜索，浏览量，主题概要,头像边框颜色根据用户组，回复内容url自动转成组件，经验条
# RUN extension require littlegolden/flarum-lang-simplified-chinese:^v0.1.70 \
#   && extension require littlegolden/flarum-lang-japanese \
#   && extension require jjandxa/flarum-ext-chinese-search \
#   && extension require michaelbelgium/flarum-discussion-views \
#   && extension require jordanjay29/flarum-ext-summaries \
#   && extension require clarkwinkelmann/flarum-ext-circle-groups \
#   && extension require lcinhk/flarum-ext-acgembed \
#   && extension require reflar/level-ranks

CMD ["/usr/local/bin/startup"]
