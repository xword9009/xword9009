#!/bin/bash
## Invoice Ninja, LAMP. Let's Encrypt installer.
# Declare variables
MYSQL_ROOT_PASSWORD='a password'
MY_SITE='url of your site'
MY_EMAIL='email address for lets encrypt'
MY_WEB_ROOT='where is invoice-ninja'
## work out hostname settings
## Last edit 
## For Debian 11 Bullseye
echo "Welcome to Blue-Canoe's flying circus"
echo "Part 1 of 4"
### TO DO - sql to create database, add user and flush privilages 
## Part 1
sleep 5
sudo apt update
sudo apt upgrade -y
sudo apt install apache2 -y
sudo apt install git python3-certbot-apache -y
sudo apt install unzip -y
sudo apt-get install software-properties-common -y
wget -O invoiceninja.zip https://github.com/invoiceninja/invoiceninja/releases/download/v5.3.86/
sudo mkdir -p "$MY_WEB_ROOT"
unzip invoiceninja.zip -d /var/www/
sudo mv /var/www/ninja /var/www/invoice-ninja
sudo chown www-data:www-data /var/www/invoice-ninja/ -R
sudo chmod 755 /var/www/invoice-ninja/storage/ -R
sudo apt install mariadb-server -y
sudo apt install php7.4-bcmath php7.4-gmp php7.4-fileinfo php7.4-gd php7.4-json php7.4-mbstring php7.4-pdo php7.4-xml php7.4-curl php7.4-zip php7.4-gmp php7.4-mysqlnd -y
## Part 2
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event proxy_fcgi setenvif
sudo systemctl restart apache2
echo "wait 5 for things to settle down"
sleep 5
while true; do
    read -p "Continue?" yn
    case $yn in
        [Yy]* ) ./p2.sh;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Part 2 of 4 mysql secure setup."
## Part 2
sudo apt -y install expect
MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Change the root password?\"
send \"$MYSQL\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt -y purge expect
sleep 5
while true; do
    read -p "Continue?" yn
    case $yn in
        [Yy]* ) ./p3.sh;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Part 3 of 4 add database"
echo "Source: https://gist.github.com/Mins/4602864"
## Part 3
echo "Adding database"
mysql -u root -p"$MYSQL_ROOT_PASSWORD"
## Create database, add user, set permissions
echo "Setup Cron Jobs"
echo "Paste into crontab"
echo "0 8 * * * /usr/bin/php7.4 /var/www/invoice-ninja/artisan ninja:send-invoices > /dev/null"
echo "0 8 * * * /usr/bin/php7.4/var/www/invoice-ninja/artisan ninja:send-reminders > /dev/null"
echo "sudo crontab -e"
while true; do
    read -p "Continue?" yn
    case $yn in
        [Yy]* ) ./p4.sh;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo "Part 4 of 4 Configure web site."
## Part 3
echo "Configure web site"
## need variable for ServerName
sudo touch /etc/apache2/sites-available/invoice-ninja.conf
sudo cat > /etc/apache2/sites-available/invoice-ninja.conf<<EOF
<VirtualHost *:80>
    ServerName "$MY_SITE"
    DocumentRoot /var/www/invoice-ninja/public

    <Directory /var/www/invoice-ninja/public>
       DirectoryIndex index.php
       Options +FollowSymLinks
       AllowOverride All
       Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/invoice-ninja.error.log
    CustomLog ${APACHE_LOG_DIR}/invoice-ninja.access.log combined

    Include /etc/apache2/conf-available/php7.4-fpm.conf
</VirtualHost>

EOF
sudo a2ensite invoice-ninja.conf
sudo a2enmod rewrite
sudo systemctl restart apache2
sleep 2
# need variables for email and domain
sudo certbot --apache --agree-tos --redirect --hsts --staple-ocsp --email "$MY_EMAIL" -d "$MY_SITE"
while true; do
    read -p "Continue?" yn
    case $yn in
        [Yy]* ) ./p4.sh;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Clean Up
# Clear variables
apt -y purge expect
# Clear up installers
