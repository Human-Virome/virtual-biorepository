#!/bin/bash

# 1. Delete the trigger file so the system is ready for the next webhook
rm -f /var/www/vbr-update-trigger

# 2. Navigate to your project directory
cd /var/www/vbr || exit

# 3. Record the current commit hash BEFORE pulling
BEFORE_PULL=$(sudo -u www-data git rev-parse HEAD)

# 4. Pull the latest code
sudo -u www-data git pull origin main

# 5. Record the commit hash AFTER pulling
AFTER_PULL=$(sudo -u www-data git rev-parse HEAD)

# 6. Compare hashes and restart only if changes occurred
if [ "$BEFORE_PULL" != "$AFTER_PULL" ]; then
    echo "Updates detected: $BEFORE_PULL -> $AFTER_PULL"
    echo "Restarting services..."
    systemctl daemon-reload
    systemctl restart plumber@8000 plumber@8001 mariadb nginx oauth2-proxy fail2ban
else
    echo "No updates found. Skipping service restarts."
fi
