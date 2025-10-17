echo "Script iniciado em $(date)" >> /var/log/monitor_nginx.log

if ! pgrep nginx > /dev/null; then
    echo "$(date): Nginx não está rodando. Tentando reiniciar..." >> /var/log/monitor_nginx.log
    nginx
    if [ $? -eq 0 ]; then
        echo "$(date): Nginx reiniciado com sucesso." >> /var/log/monitor_nginx.log
    else
        echo "$(date): Falha ao reiniciar o Nginx." >> /var/log/monitor_nginx.log
    fi
else
    echo "$(date): Nginx está rodando normalmente." >> /var/log/monitor_nginx.log
fi