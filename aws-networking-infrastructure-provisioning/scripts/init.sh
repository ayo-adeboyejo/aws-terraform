#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo "=== Helia Bootstrap Started: $(date) ==="

# Update system
apt-get update -y

# Create dev_adm user
useradd -m -s /bin/bash dev_adm
usermod -aG sudo dev_adm

# Copy SSH key from ubuntu user to dev_adm
mkdir -p /home/dev_adm/.ssh
cp /home/ubuntu/.ssh/authorized_keys /home/dev_adm/.ssh/authorized_keys
chown -R dev_adm:dev_adm /home/dev_adm/.ssh
chmod 700 /home/dev_adm/.ssh
chmod 600 /home/dev_adm/.ssh/authorized_keys

# Allow dev_adm to run sudo without password
echo "dev_adm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev_adm
chmod 440 /etc/sudoers.d/dev_adm

echo "=== dev_adm created successfully: $(date) ==="