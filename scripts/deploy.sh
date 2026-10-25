#!/usr/bin/env bash
set -euo pipefail

# Run on the Azure VM as a user with sudo privileges.
# Jenkins should securely copy app/index.html to /tmp/index.html first.
if [[ ! -f /tmp/index.html ]]; then
  echo "Expected /tmp/index.html. Copy the app file to the VM before running this script."
  exit 1
fi

sudo install -d -m 0755 /var/www/html
sudo install -m 0644 /tmp/index.html /var/www/html/index.html
sudo systemctl enable nginx
sudo systemctl restart nginx
echo "Deployment completed."
