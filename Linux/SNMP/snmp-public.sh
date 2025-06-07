#!/bin/bash

set -e

# Prompt for sysLocation and sysContact
read -rp "Enter system location (e.g., 'Server Room A'): " SYS_LOCATION
read -rp "Enter system contact (e.g., 'admin@example.com'): " SYS_CONTACT

echo "Installing SNMP and SNMPD..."
sudo apt update
sudo apt install -y snmp snmpd

echo "Backing up existing SNMP config..."
sudo cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak

echo "Writing new SNMP config..."
sudo bash -c "cat > /etc/snmp/snmpd.conf" <<EOF
# SNMP v1/v2c config
rocommunity public

# System location and contact
sysLocation $SYS_LOCATION
sysContact $SYS_CONTACT

# Bind SNMP to all interfaces (or customize)
agentAddress udp:161,udp6:[::1]:161

# Enable basic system monitoring
view   systemonly  included   .1.3.6.1.2.1.1
view   systemonly  included   .1.3.6.1.2.1.25.1

# Allow SNMP access for public community on selected OIDs
access  notConfigGroup ""      any       noauth    exact  systemonly none none
EOF

echo "Restarting SNMP service..."
sudo systemctl restart snmpd
sudo systemctl enable snmpd

echo "✅ SNMP installation and configuration complete."
