# # Use uma imagem base mínima
# FROM ubuntu:24.04

# # Defina o mantenedor
# LABEL maintainer="luizantmarquesjr@gmail.com"

# # Declare os argumentos para as versões do Nginx e PHP
# ARG NGINX_VERSION
# ARG PHP_VERSION

# # Carregue as variáveis de ambiente do .env
# ENV NGINX_VERSION=${NGINX_VERSION}
# ENV PHP_VERSION=${PHP_VERSION}

# # Instale dependências necessárias
# RUN apt-get update && apt-get install -y \
#     wget \
#     build-essential \
#     pkg-config \
#     libpcre3 \
#     libpcre3-dev \
#     zlib1g \
#     zlib1g-dev \
#     libssl-dev \
#     libxml2-dev \
#     libsqlite3-dev \
#     libcurl4-openssl-dev \
#     libjpeg-dev \
#     libpng-dev \
#     libfreetype6-dev \
#     libonig-dev \
#     libicu-dev \
#     libsodium-dev \
#     libwebp-dev \
#     libxpm-dev \
#     cron \
#     && rm -rf /var/lib/apt/lists/*

# # Baixe, configure e compile o Nginx
# RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
#     tar -xzvf nginx-${NGINX_VERSION}.tar.gz && \
#     cd nginx-${NGINX_VERSION} && \
#     ./configure --prefix=/etc/nginx \
#     --sbin-path=/usr/sbin/nginx \
#     --modules-path=/usr/lib/nginx/modules \
#     --conf-path=/etc/nginx/nginx.conf \
#     --error-log-path=/var/log/nginx/error.log \
#     --http-log-path=/var/log/nginx/access.log \
#     --pid-path=/var/run/nginx.pid \
#     --lock-path=/var/run/nginx.lock \
#     --with-http_ssl_module \
#     --with-http_v2_module \
#     --with-http_gzip_static_module \
#     --with-http_stub_status_module \
#     --with-pcre \
#     --with-stream \
#     --with-stream_ssl_module \
#     --with-threads && \
#     make -j$(nproc) && \
#     make install && \
#     cd .. && \
#     rm -rf nginx-${NGINX_VERSION} nginx-${NGINX_VERSION}.tar.gz


# # Baixe, configure e compile o PHP
# RUN wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz && \
#     tar -xzvf php-${PHP_VERSION}.tar.gz && \
#     cd php-${PHP_VERSION} && \
#     ./configure --prefix=/usr/local/php \
#     --with-config-file-path=/usr/local/php \
#     --enable-fpm \
#     --with-zlib \
#     --with-curl \
#     --with-openssl \
#     --enable-mbstring \
#     --with-mysqli \
#     --with-pdo-mysql \
#     --enable-gd \
#     --with-jpeg \
#     --with-webp \
#     --with-freetype \
#     --with-xpm \
#     --with-sodium \
#     && make -j$(nproc) && make install && \
#     mkdir -p /usr/local/php/etc/php-fpm.d && \
#     cd .. && rm -rf php-${PHP_VERSION} php-${PHP_VERSION}.tar.gz

# # Copie os arquivos de configuração para o container
# COPY php-fpm.conf /usr/local/php/etc/php-fpm.conf
# COPY www.conf /usr/local/php/etc/php-fpm.d/www.conf

# # Configure o Nginx para usar o PHP
# RUN echo 'server {\n\
#     listen 80;\n\
#     server_name localhost;\n\
#     root /var/www/html;\n\
#     index index.php index.html;\n\
#     \n\
#     location / {\n\
#     try_files $uri $uri/ =404;\n\
#     }\n\
#     \n\
#     location ~ \.php$ {\n\
#     include fastcgi_params;\n\
#     fastcgi_pass 127.0.0.1:9000;\n\
#     fastcgi_index index.php;\n\
#     fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\
#     }\n\
#     }' > /etc/nginx/nginx.conf

# # Crie o diretório raiz e o arquivo index.php com phpinfo()
# RUN mkdir -p /var/www/html && \
#     echo "<?php phpinfo();" > /var/www/html/index.php

# # Exponha as portas padrão do Nginx
# EXPOSE 80 443

# # Copie o script
# COPY monitor_nginx.sh /monitor_nginx.sh
# RUN chmod +x /monitor_nginx.sh

# # Configure o cron
# RUN echo "* * * * * root /monitor_nginx.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/monitor_nginx \
#     && chmod 0644 /etc/cron.d/monitor_nginx \
#     && crontab /etc/cron.d/monitor_nginx

# # Crie o log
# RUN touch /var/log/cron.log

# # Copie o script de inicialização
# COPY start.sh /start.sh
# RUN chmod +x /start.sh

# # Comando de inicialização — importante usar `cron -f`
# CMD ["/bin/bash", "-c", "cron -f & /start.sh"]


# Use a última versão do Alpine como imagem base
FROM alpine:3.22

# Defina o mantenedor
LABEL maintainer="luizantmarquesjr@gmail.com"

# Declare os argumentos para as versões do Nginx e PHP
ARG NGINX_VERSION
ARG PHP_VERSION

# Carregue as variáveis de ambiente do .env
ENV NGINX_VERSION=${NGINX_VERSION}
ENV PHP_VERSION=${PHP_VERSION}

# Instale dependências necessárias
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
    openrc \
    tzdata \
    && rm -rf /var/cache/apk/*

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
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf nginx-${NGINX_VERSION} nginx-${NGINX_VERSION}.tar.gz

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

# Copie os arquivos de configuração para o container
COPY php-fpm.conf /usr/local/php/etc/php-fpm.conf
COPY www.conf /usr/local/php/etc/php-fpm.d/www.conf
COPY nginx.conf /etc/nginx/nginx.conf

# # Configure o Nginx para usar o PHP
# RUN echo 'server {\n\
#     listen 80;\n\
#     server_name localhost;\n\
#     root /var/www/html;\n\
#     index index.php index.html;\n\
#     \n\
#     location / {\n\
#     try_files $uri $uri/ =404;\n\
#     }\n\
#     \n\
#     location ~ \.php$ {\n\
#     include fastcgi_params;\n\
#     fastcgi_pass 127.0.0.1:9000;\n\
#     fastcgi_index index.php;\n\
#     fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\
#     }\n\
#     }' > /etc/nginx/nginx.conf

# Crie o diretório raiz e o arquivo index.php com phpinfo()
RUN mkdir -p /var/www/html && \
    echo "<?php phpinfo();" > /var/www/html/index.php

# Exponha as portas padrão do Nginx
EXPOSE 80 443

# Copie o script
COPY monitor_nginx.sh /monitor_nginx.sh
RUN chmod +x /monitor_nginx.sh

# Configure o cron
RUN echo "* * * * * /monitor_nginx.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Crie o log
RUN touch /var/log/cron.log

# Copie o script de inicialização
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Comando de inicialização — importante usar `crond -f`
CMD ["/bin/bash", "-c", "crond -f & /start.sh"]