#!/bin/bash


#  Modified by Michael Hoyt 12/04/2016

# Make sure apache httpd is set to start at reboot

DELIVERY_PKG_TAR=$1

BASE_DIR="/root/hackwarz"
WORK_DIR="$BASE_DIR/work"
GIT_DIR="/root/git"
APP_DIR="$GIT_DIR/hackwarz_apps"

echo "DELIVERY_PKG_TAR=$DELIVERY_PKG_TAR, WORK_DIR=$WORK_DIR"

#don't need to do this as the tar file will already be extracted to /root/hackwarz
#tar -xvf $BASE_DIR/$DELIVERY_PKG_TAR -C $BASE_DIR

chkconfig httpd on

apachectl stop

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.save
cp $BASE_DIR/httpd.conf /etc/httpd/conf/httpd.conf
tar -xvf $BASE_DIR/etc_httpd_conf_other.tar -C /etc/httpd/conf

# Create web folders and set permissions
mkdir /srv/hackwarz
mkdir /srv/hackwarz/server
mkdir /srv/hackwarz/server/java
mkdir /srv/hackwarz/web
chmod -R 755 /srv/hackwarz
restorecon -r /srv/hackwarz/web

apachectl start

# Copy and configure tomcat
tar -xvf $BASE_DIR/opt_apache_tomcat.tar -C /opt
cp -a $BASE_DIR/tomcat7 /etc/init.d/
chkconfig --add tomcat7

# Add env variables to /root/.bashrc
cp /root/.bashrc /root/.bashrc.save
echo "export CATALINA_HOME=/opt/apache/tomcat/apache-tomcat-7.0.73" >> /root/.bashrc
echo "export JRE_HOME=/usr/lib/jvm/jre-1.6.0-openjdk.x86_64" >> /root/.bashrc
echo "export PATH=/usr/lib/jvm/jre-1.6.0-openjdk.x86_64/bin:$PATH:/opt/apache/tomcat/apache-tomcat-7.0.73/bin" >> /root/.bashrc
source /root/.bashrc

mkdir $GIT_DIR
mkdir $APP_DIR
mkdir "$APP_DIR/java"
mkdir "$APP_DIR/java/server"
mkdir "$APP_DIR/java/server/hackwarz-server"
mkdir "$APP_DIR/java/server/hackwarz-server/target"

cp -a $BASE_DIR/HackwarzServer.war $APP_DIR/java/server/hackwarz-server/target/

tar -xvf $BASE_DIR/scripts.tar -C $APP_DIR/

tar -xvf $BASE_DIR/web_hackwarz-scada.tar -C $APP_DIR

#Added 12/04/2016
yum install moreutils -y

cp -a $APP_DIR/web/hackwarz-scada/javascript/hmi_server_declares.js $APP_DIR/web/hackwarz-scada/javascript/hmi_server_declares.js.save
rm $APP_DIR/web/hackwarz-scada/javascript/hmi_server_declares.js
touch $APP_DIR/web/hackwarz-scada/javascript/hmi_server_declares.js

REALIP=$(ifdata -pa eth0)
echo "var HMI_SERVER_URL = 'http://$REALIP/hackwarz/server/HackwarzHandler';" >> $APP_DIR/web/hackwarz-scada/javascript/hmi_server_declares.js

#End of what is new

cd $APP_DIR/scripts/dev
./deploy_hackwarz_servlet_with_unzip.sh
./deploy_hackwarz_apps.sh

echo root:cft6Cft$| chpasswd
cat /dev/null > /root/.bash_history
rm -rf /root/hackwarz
history -c
