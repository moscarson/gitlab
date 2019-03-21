#!/bin/bash
# Per Jeff's lingo, this is the caller
SYS=$(hostname)
NOW=$(date +%Y-%m%d-%H%M)
FN="/tmp/bootfile-${SYS}-${NOW}"

hostname > ${FN}
echo ${NOW} >> ${FN}

cd /root/hackwarz

# Install RPMs
yum -y erase   jdk
yum -y install jdk

# Create caller account
useradd -m -p gopanthers frank
useradd -m -p 6d92adc0a0b6e46 ben
useradd -m -p 2bbbe3c32117f01 lauren

# Add user(s) to group(s)
usermod -a -G wheel frank

# Copy VoIP code to caller home dir
mkdir -p /home/frank/voip
cp -r ./software/* /home/frank/voip/
cp -r /home/frank/voip/lib/ /home/frank/lib/
chown -R frank:frank /home/frank/voip
chown -R frank:frank /home/frank/lib

# Add to crontab
#crontab -u frank caller-crontab.txt
crontab root-crontab.txt

# Copy tokens
mkdir -p /home/lauren/Documents
cp ./caller-tokens/README.txt /home/lauren/Documents/
chown -R lauren:lauren /home/lauren/Documents

cp ./caller-tokens/secret.wav /home/ben/
chown ben:ben /home/ben/secret.wav

mkdir -p /home/ben/Documents
cp ./caller-tokens/uber-secret.wav /home/ben/Documents/
chown -R ben:ben /home/ben/Documents

cp ./caller-tokens/congrats.txt /home/frank/
chown frank:frank /home/frank/congrats.txt

#Change root password
echo root:vgy7Vgy%| chpasswd

# clean up scripts and other artifacts
rm -rf /root/hackwarz
history -c
cat /dev/null > /root/.bash_history


