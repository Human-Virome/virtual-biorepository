#!/bin/bash

# 1. Delete the trigger file so the system is ready for the next webhook
rm -f /tmp/hvp-update-trigger

# 2. Navigate to your project directory
cd /var/www/hvp || exit

# 3. Pull the latest code
sudo -u www-data git pull origin main

# 4. Restart the necessary services
systemctl daemon-reload
systemctl restart plumber@8000 plumber@8001 mariadb nginx
