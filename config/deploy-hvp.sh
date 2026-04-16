#!/bin/bash

# 1. Delete the trigger file so the system is ready for the next webhook
rm -f /tmp/hvp-update-trigger

# 2. Navigate to your project directory
cd /var/www/hvp || exit

# 3. Record the current commit hash BEFORE pulling
BEFORE_PULL=$(git rev-parse HEAD)

# 4. Pull the latest code
sudo -u www-data git pull origin main

# 5. Record the commit hash AFTER pulling
AFTER_PULL=$(git rev-parse HEAD)

# 6. Compare hashes and restart only if changes occurred
if [ "$BEFORE_PULL" != "$AFTER_PULL" ]; then
    echo "Updates detected: $BEFORE_PULL -> $AFTER_PULL. Restarting services..."
    systemctl daemon-reload
    systemctl restart plumber@8000 plumber@8001 mariadb nginx
else
    echo "No updates found. Skipping service restarts."
fi
