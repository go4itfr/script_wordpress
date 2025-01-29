#!/bin/bash

# Variables
DOMAIN="webpartner.cloud"
WEBROOT="/var/www/webpartner"
DB_NAME="webpartner_db"
DB_USER="webpartner_user"
DB_PASS="Varsovie7!@Np"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

# Mise à jour du système
apt update && apt upgrade -y

# Installation des paquets nécessaires
apt install -y nginx mariadb-server mariadb-client php php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip wget certbot python3-certbot-nginx

# Démarrage et activation des services
systemctl enable --now nginx mariadb php-fpm

# Sécurisation de MariaDB
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Création de la base de données et de l'utilisateur
mysql -e "CREATE DATABASE $DB_NAME;"
mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Optimisation de MariaDB
echo "[mysqld]
innodb_buffer_pool_size = 256M
query_cache_type = 1
query_cache_size = 32M
max_connections = 100
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table = 1" >> /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb

# Création du répertoire web
mkdir -p $WEBROOT
chown -R www-data:www-data $WEBROOT

# Téléchargement et installation de WordPress
wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
tar -xzf /tmp/latest.tar.gz -C $WEBROOT --strip-components=1
cp $WEBROOT/wp-config-sample.php $WEBROOT/wp-config.php

# Configuration de WordPress
sed -i "s/database_name_here/$DB_NAME/" $WEBROOT/wp-config.php
sed -i "s/username_here/$DB_USER/" $WEBROOT/wp-config.php
sed -i "s/password_here/$DB_PASS/" $WEBROOT/wp-config.php
chown -R www-data:www-data $WEBROOT

# Configuration Nginx optimisée
cat > $NGINX_CONF <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root $WEBROOT;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(jpg|jpeg|gif|png|webp|svg|ico|css|js|woff|woff2|eot|ttf|otf|ttc|font.css)\$ {
        expires max;
        log_not_found off;
    }

    location = /robots.txt { access_log off; log_not_found off; }
    location = /favicon.ico { access_log off; log_not_found off; }
}
EOL

# Activation de la configuration et rechargement de Nginx
ln -s $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Obtention du certificat SSL
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Finalisation
echo "Installation terminée. WordPress est accessible sur https://$DOMAIN"
