#!/bin/bash

#BoockStack installation 
#Automatisation d'un installation d'un serveur bookstack
#
#
#
#Auteur	: Letang Nicolas
#Email	: nicolas.letang.travail@homtmail.com
#Version: 1.0


#---Mise à jours et installation des packages---#

DOMAIN='my_bookstack.com'
DB_password='passBookstack'


function update() 
{
	apt-get update && apt-get upgrade -y
}

function package_install()
{
	apt-get install unzip curl php7.4-fpm php7.4-common php7.4-mysql php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-gd php7.4-xml php7.4-cli php7.4-zip php7.4-soap php7.4-imap nginx mariadb-server mariadb-client -y 
}

function mariadb_secure_install()
{	
	mysql_secure_installation 
	mariadb -u root --execute="CREATE DATABASE bookstack"
	mariadb -u root --execute="CREATE USER 'bookstack'@'localhost' IDENTIFIED BY '$DB_password';"
	mariadb -u root --execute="GRANT ALL ON bookstack.* TO 'bookstack'@'localhost'; FLUSH PRIVILEGES;"
}

function bookstack_download()
{
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
	cd /var/www/
	mkdir -p my_bookstack/html
	cd my_bookstack/html
	git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack
	cd bookstack
	composer install --no-interaction  
}

function bookstack_env()
{
	cp .env.example .env
	sed -i.bak "s@APP_URL=.*\$@APP_URL=http://$DOMAIN@" .env
	sed -i.bak 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
	sed -i.bak 's/DB_USERNAME=.*$/DB_USERNAME=bookstack/' .env
	sed -i.bak "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_password/" .env

}

function migrate_data_base()
{
	php artisan key:generate --no-interaction --force
	php artisan migrate --no-interaction --force 
}

function change_permission()
{
	chown -R www-data:www-data /var/www/my_bookstack/ && chmod -R 755 /var/www/my_bookstack
}

function nginx_configuration()
{	

	#sed -i.bak 's/listen 80 default_server ;$/listen 80; /' /etc/nginx/sites-available/default 
	#sed -i.bak 's/listen [::]:80 default_server ;$/listen [::]:80; /'
	#need remove default_server option in the default nginx conf


	uri='$uri'
	query_string='$query_string'
	cat > /etc/nginx/sites-available/my_bookstack << EOL
server {
  listen 80 defautl_server;
  listen [::]:80 defautl_server;

  server_name my_bookstack.com ; 

  root /var/www/my_bookstack/html/bookstack/public;
  index index.php index.html;

  location / {
    try_files $uri $uri/ /index.php?$query_string;
  }	
  
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
  }
}	
	
EOL

	ln -s /etc/nginx/sites-available/bookstack /etc/nginx/sites-enabled/
	systemctl restart nginx.service 
}

echo "###--BookStack installation--###"
sleep 2
echo "###--Package update--###"
update
sleep 5
echo "###--Package installation--###"
package_install
sleep 5
mariadb_secure_install
sleep 5 
bookstack_download
sleep 5
bookstack_env
sleep 5
migrate_data_base
sleep 5 
change_permission
sleep 5 
nginx_configuration