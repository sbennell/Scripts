sudo apt-get install snmpd -y
sudo mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.old
sudo cat > /etc/snmp/snmpd.conf << EOF
# Change RANDOMSTRINGGOESHERE to your preferred SNMP community string
com2sec readonly  default         Bennellit

group MyROGroup v2c        readonly
view all    included  .1                               80
access MyROGroup ""      any       noauth    exact  all    none   none

sysLocation 26 Partridge Way, Mooroolbark, Vic 3138
sysContact Stewart Bennell <server@lab-network.xyz>

#OS Distribution Detection
extend distro /usr/bin/distro

#Hardware Detection
# (uncomment for x86 platforms)
#extend manufacturer '/bin/cat /sys/devices/virtual/dmi/id/sys_vendor'
#extend hardware '/bin/cat /sys/devices/virtual/dmi/id/product_name'
#extend serial '/bin/cat /sys/devices/virtual/dmi/id/product_serial'

# (uncomment for ARM platforms)
#extend hardware '/bin/cat /sys/firmware/devicetree/base/model'
#extend serial '/bin/cat /sys/firmware/devicetree/base/serial-number'
EOF
sudo curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
sudo chmod +x /usr/bin/distro
sudo service snmpd restart
