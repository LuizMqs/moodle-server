#!/bin/bash
# Verifica se o PHP-FPM já está rodando
if ! pgrep php-fpm > /dev/null; then
    echo "Iniciando o PHP-FPM..."
    /usr/local/php/sbin/php-fpm &
else
    echo "PHP-FPM já está rodando."
fi

# Inicia o Nginx
echo "Iniciando o Nginx..."
nginx -g "daemon off;"