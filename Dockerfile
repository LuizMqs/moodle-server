# Etapa 1: Build (compilação do PHP e Nginx)
FROM alpine:3.22.2 AS build

LABEL maintainer="luizantmarquesjr@gmail.com"

# Declare os argumentos para as versões do Nginx e PHP
ARG NGINX_VERSION
ARG PHP_VERSION

# Carregue as variáveis de ambiente do .env
ENV NGINX_VERSION=${NGINX_VERSION}
ENV PHP_VERSION=${PHP_VERSION}

# Instale dependências necessárias para compilação
RUN apk add --no-cache \
    wget \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    libxml2-dev \
    sqlite-dev \
    curl-dev \
    jpeg-dev \
    libpng-dev \
    freetype-dev \
    oniguruma-dev \
    icu-dev \
    libsodium-dev \
    libwebp-dev \
    libxpm-dev \
    linux-headers \
    bash \
    tzdata

# Configure o timezone (opcional)
RUN cp /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone

# Baixe, configure e compile o Nginx
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzvf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-pcre \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf nginx-${NGINX_VERSION} nginx-${NGINX_VERSION}.tar.gz

# Baixe, configure e compile o PHP
RUN wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz && \
    tar -xzvf php-${PHP_VERSION}.tar.gz && \
    cd php-${PHP_VERSION} && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php \
    --enable-fpm \
    --with-zlib \
    --with-curl \
    --with-openssl \
    --enable-mbstring \
    --with-mysqli \
    --with-pdo-mysql \
    --enable-gd \
    --with-jpeg \
    --with-webp \
    --with-freetype \
    --with-xpm \
    --with-sodium \
    && make -j$(nproc) && make install && \
    mkdir -p /usr/local/php/etc/php-fpm.d && \
    cd .. && rm -rf php-${PHP_VERSION} php-${PHP_VERSION}.tar.gz

# Etapa 2: Runtime (imagem final mínima)
FROM alpine:3.22.2

LABEL maintainer="luizantmarquesjr@gmail.com"

# Instale dependências de runtime necessárias para o PHP e Nginx
RUN apk add --no-cache \
    libxml2 \
    libpng \
    libjpeg-turbo \
    freetype \
    icu \
    libsodium \
    libwebp \
    libxpm \
    curl \
    sqlite-libs \
    oniguruma \
    bash \
    tzdata \
    pcre \
    zlib \
    openssl

# Configure o timezone (opcional)
RUN cp /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone

# Crie os diretórios necessários para o Nginx
RUN mkdir -p /var/log/nginx /var/run

# Copie os binários do PHP e Nginx da etapa de build
COPY --from=build /usr/local/php /usr/local/php
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx

# Copie os arquivos de configuração e scripts necessários
COPY php-fpm.conf /usr/local/php/etc/php-fpm.conf
COPY www.conf /usr/local/php/etc/php-fpm.d/www.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY monitor_nginx.sh /monitor_nginx.sh
COPY start.sh /start.sh

# Ajuste permissões dos scripts
RUN chmod +x /monitor_nginx.sh /start.sh

# Configure o cron
RUN echo "* * * * * /monitor_nginx.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Crie o log
RUN touch /var/log/cron.log

# Configure o PATH para incluir o PHP e o Nginx
ENV PATH="/usr/local/php/bin:/usr/local/php/sbin:$PATH"

# Crie o diretório raiz e o arquivo index.php com phpinfo()
RUN mkdir -p /var/www/html && \
    echo "<?php phpinfo();" > /var/www/html/index.php

# Exponha as portas padrão do Nginx
EXPOSE 80 443

# Comando de inicialização — importante usar `crond -f`
CMD ["/bin/bash", "-c", "crond -f & /start.sh"]