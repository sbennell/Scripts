#!/bin/bash

# Variables
COMMUNITY="0982"
SUBNET="10.142.196.0/22"
SNMP_CONF="/etc/snmp/snmpd.conf"

# Update the package list
echo "Updating package list..."
sudo apt update -y

# Install snmpd if it's not installed
echo "Installing snmpd..."
sudo apt install snmpd snmp -y

# Backup existing snmpd.conf
echo "Backing up the current snmpd.conf file..."
sudo cp $SNMP_CONF $SNMP_CONF.bak

# Modify the snmpd.conf file to set community and subnet restrictions
echo "Configuring SNMP with community name '$COMMUNITY' and subnet '$SUBNET'..."
echo "rocommunity $COMMUNITY $SUBNET" | sudo tee -a $SNMP_CONF

# Restart snmpd service to apply changes
echo "Restarting SNMP service..."
sudo systemctl restart snmpd

# Allow SNMP traffic through UFW (firewall)
echo "Allowing SNMP traffic from $SUBNET..."
sudo ufw allow from $SUBNET to any port 161 proto udp

# Show the status of the snmpd service
echo "Checking SNMP service status..."
sudo systemctl status snmpd | grep "Active"

# Test SNMP access using snmpwalk
echo "Testing SNMP access with community name '$COMMUNITY'..."
snmpwalk -v2c -c $COMMUNITY localhost

echo "SNMP setup completed successfully!"
