#!/bin/bash

# Install packages.
cd rpms
yum -y --nogpgcheck localinstall httpd-2.2.3-92.el5.centos.x86_64.rpm
yum -y --nogpgcheck localinstall dhcp-3.0.5-33.el5_9.x86_64.rpm
cd ..

# Copy dhcpd.conf
cp etc/dhcpd.conf /etc/.

# Set up services to start automatically.
chkconfig httpd on
chkconfig dhcpd on

# Start services
service httpd start
service dhcpd start

# Create user accounts.
useradd chestern
useradd georgep
useradd dougm
useradd dwighte

# Deploy files.
alias cp=cp
cp -rf www /var/.
cp -rf root /.
cp -rf home /.

# Set home dir ownership.
chown -R chestern /home/chestern
chown -R georgep /home/georgep
chown -R dougm /home/dougm
chown -R dwighte /home/dwighte

# clean up scripts and other artifacts
rm -rf /root/hackwarz
history -c
cat /dev/null > /root/.bash_history


