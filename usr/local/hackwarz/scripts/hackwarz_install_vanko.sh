#!/bin/bash

setenforce permissive

SYS=$(hostname)
NOW=$(date +%Y-%m%d-%H%M)
FN="/tmp/bootfile-${SYS}-${NOW}"

hostname > ${FN}
echo ${NOW} >> ${FN}

cd /root/hackwarz
#tar -xf vanko.tar
#cp myrepo.repo /etc/yum.repos.d/
#cd vankoRepo
#yum localinstall -y deltarpm-3.6-3.el7.x86_64.rpm
#yum localinstall -y libxml2-2.9.1-6.el7_2.3.x86_64.rpm
#yum localinstall -y libxml2-python-2.9.1-6.el7_2.3.x86_64.rpm
#yum localinstall -y python-deltarpm-3.6-3.el7.x86_64.rpm
#yum localinstall -y createrepo-0.9.9-25.el7_2.noarch.rpm
#createrepo --database .



#Change root password
echo root:1q2w3e!Q@W#E | chpasswd

#Place tokens on VM
touch ~/498f2abca7a1a6a.classified
touch /tmp/32501461ba9dca5.txt
echo fbdb9aa673ad019 >> /etc/hosts

#install needed packages
yum -y install httpd mariadb-server mysql php php-mysql

#Start and enable services
systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb

#Setup mariadb. Might work, but you might know more about this. Basically a command
#where we need to answer a bunch of prompts.
printf '\nY\n1q2w3e1q2w3e\n1q2w3e1q2w3e\nY\nN\nY\nY' | mysql_secure_installation

#Load the database
mysql -u "root" "-p1q2w3e1q2w3e"  < "westworld.sql"

#Set up the website in apache
#cp westworld.tar /var/www/html/
#cd /var/www/html
#tar -xf westworld.tar
tar xvf /root/hackwarz/westworld.tar -C /var/www/html


#Change root password
#echo root:xsw@xsW2| chpasswd

# clean up scripts and other artifacts
rm -rf /root/hackwarz

#Clear history and add final token into the history
cat /dev/null > /root/.bash_history
history -c
echo 498f2abca7a1a6a >> ~/.bash_history


