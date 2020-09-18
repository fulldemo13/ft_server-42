
FROM debian:buster

RUN apt-get update && \
apt-get upgrade && \
apt-get -y install mariadb-server &&\
apt-get -y install wget && \
apt -y install php7.3-fpm &&\
apt-get -y install php-mysql &&\
apt-get install -y libnss3-tools &&\
apt-get -y install nginx

RUN wget https://wordpress.org/latest.tar.gz && \
	cp latest.tar.gz /var/www/html/ && rm latest.tar.gz && \
	cd /var/www/html/ && ls && tar -xf latest.tar.gz && rm latest.tar.gz && \
	cd wordpress && cp -r * ../ && cd .. && rm -rf wordpress index.nginx-debian.html
COPY src/wp-config.php /var/www/html/

RUN mkdir -p /var/www/localhost
COPY /src/nginx-host-conf /etc/nginx/sites-available/localhost
RUN ln -fs /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/default

RUN mkdir ~/mkcert &&\
	cd ~/mkcert &&\
	wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64 &&\
	mv mkcert-v1.4.1-linux-amd64 mkcert &&\
  	chmod +x mkcert &&\
	./mkcert -install && ./mkcert localhost

COPY src/wordpress.sql .
RUN service mysql start &&\
echo "CREATE DATABASE wordpress;" | mysql -u root &&\
echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost';" | mysql -u root &&\
echo "FLUSH PRIVILEGES;" | mysql -u root &&\
echo "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root &&\
	mysql wordpress -u root --password=  < wordpress.sql

RUN cd &&\
wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-english.tar.gz &&\
mkdir /var/www/html/phpmyadmin &&\
tar xzf phpMyAdmin-4.9.0.1-english.tar.gz --strip-components=1 -C /var/www/html/phpmyadmin
COPY /src/config.inc.php /var/www/html/phpmyadmin/config.inc.php

RUN chown -R www-data:www-data /var/www/* &&\
chmod -R 755 /var/www/*

EXPOSE 80 443

CMD service mysql restart && /etc/init.d/php7.3-fpm start && service nginx restart && sleep infinity

