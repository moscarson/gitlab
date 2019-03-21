#!/bin/bash
# Per Jeff's lingo, this is the callee

SYS=$(hostname)
NOW=$(date +%Y-%m%d-%H%M)
FN="/tmp/bootfile-${SYS}-${NOW}"

hostname > ${FN}
echo ${NOW} >> ${FN}

cd /root/hackwarz

# Install RPMs
yum -y erase   jdk
yum -y install jdk

# Create callee account(s)
useradd -m -p p@$$w0rd john
useradd -m -p s1mpl3P@$$ sara
useradd -m -p password larry
useradd -m -p 379f65a805733a6 curly
useradd -m -p 72f280958efac7b moe

# Add user(s) to group(s)
usermod -a -G wheel john
usermod -a -G wheel sara
usermod -a -G wheel larry
usermod -a -G wheel curly
usermod -a -G wheel moe

# Copy capture.sh script to moe home dir. This is to provide a clue to 
# perform a packet capture
cp ./capture.sh /home/moe/
chown moe:moe /home/moe/capture.sh

# Copy VoIP code to callee home dir
mkdir /home/john/voip
cp -r ./software/* /home/john/voip/
cp -r /home/john/voip/lib/ /home/john/lib/
chown -R john:john /home/john/voip
chown -R john:john /home/john/lib

# Add to crontab
crontab -u john callee-crontab.txt

# Copy tokens
mkdir /home/sara/Documents
cp ./callee-tokens/todo-list.csv /home/sara/Documents/
chown -R sara:sara /home/sara/Documents

cp ./callee-tokens/data.dat /home/curly/
chown curly:curly /home/curly/data.dat

#Change root password
echo root:cde3Cde#| chpasswd

# clean up scripts and other artifacts
rm -rf /root/hackwarz
history -c
cat /dev/null > /root/.bash_history


