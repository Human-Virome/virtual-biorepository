
## Purpose

This repository contains the Human Virome Project's Virtual Biorepository website.

This website offers a centralized and standardized process for coordinating
centers to upload sample metadata. It also generates files from this metadata to
be used in submitting sequencing reads to SRA.


## Implementation

An AWS Lightsail Ubuntu 24.04 instance was configured as follows:

* Security group = ports 22, 80, 443, and 3306

```bash
sudo bash

# Create 2GB Swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# System Updates & Dependencies
apt update && apt upgrade -y
apt install -y nginx mariadb-server r-base libcurl4-openssl-dev libssl-dev libxml2-dev
snap install aws-cli --classic
R -e "install.packages('pak', repos='https://cloud.r-project.org')"
R -e "pak::pak(c('bcrypt', 'DBI', 'jsonlite', 'plumber', 'pool', 'openssl', 'openxlsx2', 'RMariaDB'))"

git clone https://github.com/Human-Virome/virtual-biorepository.git /var/www/hvp
git config --global --add safe.directory /var/www/hvp
chown -R www-data:www-data /var/www/hvp

# Apply Configs (Backup defaults first to prevent symlink errors)
mv /etc/nginx/nginx.conf  /etc/nginx/nginx.conf.bak
mv /etc/mysql/mariadb.cnf /etc/mysql/mariadb.cnf.bak 
ln -s /var/www/hvp/config/nginx.conf          /etc/nginx/nginx.conf
ln -s /var/www/hvp/config/mariadb.cnf         /etc/mysql/mariadb.cnf
ln -s /var/www/hvp/config/plumber@.service    /etc/systemd/system/plumber@.service
ln -s /var/www/hvp/config/hvp-updater.service /etc/systemd/system/hvp-updater.service
ln -s /var/www/hvp/config/hvp-updater.path    /etc/systemd/system/hvp-updater.path

# Setup Systemd
systemctl daemon-reload
systemctl enable --now hvp-updater.path
systemctl enable --now plumber@8000
systemctl enable --now plumber@8001

# Restart Services
systemctl restart mariadb
systemctl restart nginx

mysql -u root < /var/www/hvp/config/database.sql
```
