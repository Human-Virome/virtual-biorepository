
## Purpose

This repository contains the Human Virome Project's Virtual Biorepository website.

This website offers a centralized and standardized process for coordinating
centers to upload sample metadata. It also generates files from this metadata to
be used in submitting sequencing reads to SRA.


## Implementation

An AWS Lightsail Debian 13.3 instance was configured as follows:

On 'Networking' tab, allow ports 22 (ssh), 80 (http), 443 (https), and 3306 (mysql).

```bash
sudo bash

# Create 2GB Swap
fallocate -l 2G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab


# System Updates & Dependencies
apt update && apt upgrade -y
apt install -y nginx certbot mariadb-server r-base awscli git fail2ban
R -e "install.packages('pak', repos='https://r-lib.github.io/p/pak/stable/source/linux-gnu/x86_64'); \
      options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/trixie/latest'));      \
      pak::pak(c('DBI', 'jsonlite', 'plumber', 'pool', 'openxlsx2', 'RMariaDB', 'sodium'))"

certbot certonly --webroot -w /var/www/html -d hvp.jplab.net --register-unsafely-without-email --agree-tos


# Install OAuth2 Proxy
wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v7.15.2/oauth2-proxy-v7.15.2.linux-amd64.tar.gz
tar -xf oauth2-proxy-v7.15.2.linux-amd64.tar.gz
mv oauth2-proxy-v7.15.2.linux-amd64/oauth2-proxy /usr/local/bin/
chmod +x /usr/local/bin/oauth2-proxy
rm -rf oauth2-proxy-v7.15.2.linux-amd64*

# Change these values. Generate cookie_secret with `openssl rand -base64 32`.
echo 'OAUTH2_PROXY_CLIENT_ID="your_globus_client_id"'          >  /etc/oauth2-proxy.env
echo 'OAUTH2_PROXY_CLIENT_SECRET="your_globus_client_secret"'  >> /etc/oauth2-proxy.env
echo 'OAUTH2_PROXY_COOKIE_SECRET="your_32_byte_cookie_secret"' >> /etc/oauth2-proxy.env
chmod 600 /etc/oauth2-proxy.env


git clone https://github.com/Human-Virome/virtual-biorepository.git /var/www/hvp
git config --global --add safe.directory /var/www/hvp
chown -R www-data:www-data /var/www/hvp

# Apply Configs (Backup defaults first to prevent symlink errors)
mv /etc/nginx/nginx.conf  /etc/nginx/nginx.conf.bak
mv /etc/mysql/mariadb.cnf /etc/mysql/mariadb.cnf.bak 
ln -s /var/www/hvp/config/nginx.conf           /etc/nginx/nginx.conf
ln -s /var/www/hvp/config/mariadb.cnf          /etc/mysql/mariadb.cnf
ln -s /var/www/hvp/config/jail.local           /etc/fail2ban/jail.local
ln -s /var/www/hvp/config/oauth2-proxy.conf    /etc/oauth2-proxy.conf
ln -s /var/www/hvp/config/oauth2-proxy.service /etc/systemd/system/oauth2-proxy.service
ln -s /var/www/hvp/config/plumber@.service     /etc/systemd/system/plumber@.service
ln -s /var/www/hvp/config/hvp-updater.service  /etc/systemd/system/hvp-updater.service
ln -s /var/www/hvp/config/hvp-updater.path     /etc/systemd/system/hvp-updater.path

# Setup Systemd
systemctl daemon-reload
systemctl enable --now hvp-updater.path
systemctl enable --now oauth2-proxy
systemctl enable --now plumber@8000
systemctl enable --now plumber@8001

# Restart Services
systemctl restart mariadb nginx fail2ban

mysql -u root < /var/www/hvp/config/database.sql
```
