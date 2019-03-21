#!/bin/bash

#Updated 11/23/2016 - Michael Hoyt
# 11/26/2016 - Minor updates - M. Oscarson
  # removed version numbers from packages
  # tweaked directory traversal just a bit
yum install -y gnome-user-share mod_perl mod_python system-config-httpd webalizer
yum install -y bind-utils bind-libs bind
yum install -y libsmbclient samba-client samba-common samba
yum install -y mod_ssl httpd-manual httpd
yum install -y vsftpd
yum install -y perl-Time-Duration perl-TimeDate moreutils
rpm -e bind-chroot
yes | cp -R etc /
yes | cp -R var /

REALIP=$(ifdata -pa eth0)
sed -i -e 's/REPLACEIP/'$REALIP'/' /etc/named.conf


function adduser {

useradd cd957359cff9185
passwd cd957359cff9185 << EOF
abc123
abc123
EOF


useradd bbanner
passwd bbanner << EOF
hulk
hulk
EOF

useradd john
passwd john << EOF
p@$$w0rd
p@$$w0rd
EOF

}

yes | cp -R home /
ln -s /etc/ /var/6cfd48a90c5b75a
chmod 775 /etc/shadow

service httpd restart
service named restart
service smb restart
service vsftpd restart
chkconfig httpd on
chkconfig named on
chkconfig smb on
chkconfig vsftpd on

adduser

#Change root password
echo root:mko0Mko#| chpasswd

# clean up scripts and other artifacts
rm -rf /root/hackwarz
history -c
cat /dev/null > /root/.bash_history


