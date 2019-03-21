#!/bin/bash
SYS=$(hostname)
NOW=$(date +%Y-%m%d-%H%M)
FN="/tmp/bootfile-${SYS}-${NOW}"

hostname > ${FN}
echo ${NOW} >> ${FN}

WIN2003IP=REPLACEWIN2003IP

function onboot {

        for file in /etc/sysconfig/network-scripts/ifcfg-eth*; do
                sed -i 's/ONBOOT=.*/ONBOOT=yes/' $file
        done

}

function restartnetwork {

        systemctl restart network.service

}

function disablerepo {

        for file in /etc/yum.repos.d/CentOS* /etc/yum/pluginconf.d/*conf ; do
                sed -i 's/enabled=.*/enabled=0/' $file
        done

}

function enablelocalrepo {

        for file in /etc/yum.repos.d/hackwarz.repo; do
                sed -i 's/enabled=.*/enabled=1/' $file
        done

}

function installapache {

        yum -y install httpd --nogpgcheck

}

function starthttpd {

        systemctl start httpd

}

function enablehttpd {

        systemctl enable httpd

}

function  modssl {

        yum -y install mod_ssl --nogpgcheck

}

function  phpmyadmin {

        yum -y install phpmyadmin --nogpgcheck

}

function php {

        yum -y install php --nogpgcheck

}

function installmysql {

        yum -y install mysql mysql-server --nogpgcheck

}

function startmysql {

        systemctl start mysqld

}

function enablemysql {

        systemctl enable mysqld

}

function login {

cat << 'EOF' > /tmp/setupdb.sql
#!/bin/bash

create database if not exists Accounts;
use Accounts;
create table if not exists users (username varchar(20) NOT NULL,
password varchar(20) NOT NULL);
insert into users (username, password)
values
("micah","r00tcabb@g3"),
("token","f5fa1a51d158339"),
("password","zoolander");

create database if not exists FavoriteCharacters;
use FavoriteCharacters;
create table if not exists nametable (firstname varchar(20) NOT NULL,
lastname varchar(20) NOT NULL);
insert into nametable (firstname, lastname)
values
("SpongeBob","Squarepants"),
("Patrick","Star"),
("Squidward","Tentacles"),
("Sandy","Squirrel"),
("b50e4f901e71adb","67366f8d5d0c12f");

use mysql;
create table if not exists mysql_schema (Name varchar(20) NOT NULL);
insert into mysql_schema (Name)
values
("53bcd611ef26157");
EOF

        echo "start    run of /tmp/setupdb.sql"
        mysql -u root < /tmp/setupdb.sql
        echo "finished run of /tmp/setupdb.sql"

}

function copytokens {

        cp ./tokens/Classified /root
        DIR=/home/intern/.local/share/Trash/files
        mkdir -p ${DIR}
        cp ./tokens/DesktopBackground.xcf ${DIR}
        cp ./tokens/f1040.pdf ${DIR}
        cp -r ./tokens/WorkSchematics ${DIR}

}

function configs {

        cp -f ./configs/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf
        cp -f ./configs/config.inc.php /etc/phpMyAdmin/config.inc.php
        cp -f ./configs/ssl.conf /etc/httpd/conf.d/ssl.conf
        cp -f ./configs/httpd.conf /etc/httpd/conf/httpd.conf
        cp -f ./configs/ContactForm.php /var/www/html/ContactForm.php
        cp -f ./configs/query.php /var/www/html/query.php
}


function setbackground {

        yum -y install dconf --nogpgcheck
        mkdir -p /etc/dconf/db/local.d/locks
        cp -f ./configs/background /etc/dconf/db/local.d/locks/background
        cp -f ./configs/desktop /etc/dconf/db/local.d/desktop
        dconf update

}

function ssl {

        mkdir -p /etc/httpd/ssl
        cp -f ./configs/apache.crt /etc/httpd/ssl/apache.crt
        cp -f ./configs/apache.key /etc/httpd/ssl/apache.key

}

function adduser {

useradd micah
passwd micah << EOF
r00tcabb@g3
r00tcabb@g3
EOF
usermod -aG wheel micah


useradd intern
passwd intern << EOF
toor
toor
EOF
usermod -aG wheel intern

}

function restart {

        systemctl restart httpd

}

#starts networking on boot
onboot

#restarts networking so the changes take effect
restartnetwork

# disable remote repositories
disablerepo

#enable local repository
enablelocalrepo

#installs apache web server
installapache

#installs ssl
modssl

#installs phpmyadmin
phpmyadmin

#installs php
php

#installs mysql
installmysql

#starts httpd
starthttpd

#enables httpd
enablehttpd

#starts mysql
startmysql

#enables mysql
enablemysql

#Logs you into Mysql command prompt
login

#Selects mysql database for use
#usemysql

#copies token files to their locations on the machine
copytokens

#copied files for background and sets background
setbackground

#copies config files to their destinations
configs

#makes ssl directory and copies ssl crt and key files into it
ssl

#adds user micah
adduser

#restarts apache so changes can take affect
restart

#add /etc/hosts entry for windows host
echo "${WIN2003IP} win2003box" >> /etc/hosts

# Set root passwd
#Change root password
echo root:t00rt00r!2| chpasswd

# clean up scripts and other artifacts
rm -rf /root/hackwarz
history -c
cat /dev/null > /root/.bash_history


