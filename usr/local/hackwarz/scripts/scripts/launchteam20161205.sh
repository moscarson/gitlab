#!/bin/bash

# Servers:

# 34.192.192.33
#		description:	staging area for developers to stage their stuff
# 		login:			ssh -i ./hackwarzdev.pem centos@34.192.192.33

# 34.192.172.134
# 		description:	centos 7 yum repo server
#		login:  		ssh -i ./hackwarzAdmin.pem centos@34.192.172.134

# REPOS
# This script depends on a yum repolistory with RPMs available.  the 4 repos required include
#	centos7
#	centos511
#	shellshock
#	vanko
# As these repos are populated with RPMs, you must update the repo to make the RPMs available
# 	For centos7:		createrepo --update /var/www/html/rpms/centos7
#	For the others:		createrepo -s sha /var/www/html/rpms/{REPONAME}

# NAT GATEWAY
# Access to the yum repo is provided by use of a NAT Gateway in each VPC. 
# Once installation is complete, delete the NAT gateway from the VPC
# (This script will complete, but the instance deploys may not yet be complete.  log in to each 
# instance and ensure complete before deleting that gateway

##############################################################		
# Required OS
#
# VMs
# Killian       Windows 2003    Philip
# Hulk          CentOS 5.11     Michael
# Pepper        CentOS 5.11     Jeff
# Rhodes        CentOS 5.11     Jeff
# Romanoff      CentOS 5.11     Gerald
# Jarvis        CentOS 5.4     	Terry
# Fury          CentOS 7        Philip
# Vanko         CentOS 7        Chris
# kaliws1	Kali linux	
# kaliws2	Kali linux	
# kaliws3	Kali linux	
#
#
# To log in to admin server
# ssh -i ./hackwarzAdmin.pem centos@54.152.93.20
# sudo su -


if [ $# -ne 1 ] ; then
  echo "Usage:  $0 teamname"
  exit 1
fi

readonly TEAMNAME=$1
readonly TEAMTMP=$(echo ${TEAMNAME}|cut -c1-4|tr '[A-Z]' '[a-z]')

if [[ $TEAMTMP -ne "team" ]] ; then
  echo "Usage: team followed by team number"
  exit 2
fi




# Environment setup
readonly NOW=$(date +%Y%m%d%H%M)
readonly BASEDIR="/usr/local/hackwarz"
readonly SCRIPTSDIR="${BASEDIR}/scripts"
readonly TMPDIR="${BASEDIR}/tmp"
readonly PROPSDIR="${BASEDIR}/props"
readonly PROPSFILE="${PROPSDIR}/props${NOW}"
readonly LOGDIR="${BASEDIR}/log"
readonly LOGFILE="${LOGDIR}/hwdeploy${NOW}"
readonly USERDATADIR="${BASEDIR}/userdata"

# Ensure BASEDIR exists
if [ ! -d "${BASEDIR}" ] ; then
  mkdir ${BASEDIR}
fi

# Ensure SCRIPTSDIR exists
if [ ! -d "${SCRIPTSDIR}" ] ; then
  mkdir ${SCRIPTSDIR}
fi

# Ensure TMPDIR exists
if [ ! -d "${TMPDIR}" ] ; then
  mkdir ${TMPDIR}
fi

# Ensure PROPSDIR exists
if [ ! -d "${PROPSDIR}" ] ; then
  mkdir ${PROPSDIR}
fi

# Ensure LOGDIR exists
if [ ! -d "${LOGDIR}" ] ; then
  mkdir ${LOGDIR}
fi

# Ensure USERDATADIR exists
if [ ! -d "${USERDATADIR}" ] ; then
  mkdir ${USERDATADIR}
fi

readonly REGION="us-east-1"
readonly KEYNAME="hackwarzdev"
readonly INSTANCETYPECENTOS="t2.micro"
readonly INSTANCETYPEKALI="m3.large"
readonly INSTANCETYPEWINDOWS="t2.micro"
readonly INSTANCETYPEUBUNTU="m3.medium"
readonly IMAGEIDCENTOS54="ami-43303454"
readonly IMAGEIDCENTOS511="ami-96ab9c81"
readonly IMAGEIDCENTOS6="ami-fcae99eb"
readonly IMAGEIDCENTOS7="ami-91ab9c86"
readonly IMAGEIDUBUNTU="ami-cc605fdb"
readonly IMAGEIDKALI="ami-06112911"
readonly IMAGEIDWINDOWS="ami-7af4cc6d"






##############################################################		
# Create VPC
readonly VPCINFO=$(aws ec2 create-vpc --cidr-block 20.20.0.0/16)
readonly VPCID=$(echo $VPCINFO|sed -e 's/\s\+/\n/g'|grep vpc\-|awk -F\" '{print $2}')
echo "VPCID: ${VPCID}"
		
##############################################################		
# Create subnets
# Create Private Subnet1
readonly PRIVATESUBNET=$(aws ec2 create-subnet --vpc-id ${VPCID} --cidr-block 20.20.10.0/24)
readonly PRIVSUBNETID=$(echo ${PRIVATESUBNET}|sed -e 's/\s\+/\n/g'|grep subnet-|awk -F\" '{print $2}')
echo "PRIVSUBNETID:  ${PRIVSUBNETID}"

# Private subnet2 was originally indended to hold the hidden Windows box.  We since decided to hide that system
# and restrict access from fury only by modifying the security group for the Windows system
# Create Private Subnet2
#readonly PRIVATESUBNET2=$(aws ec2 create-subnet --vpc-id ${VPCID} --cidr-block 20.20.15.0/24)
#readonly PRIVSUBNETID2=$(echo ${PRIVATESUBNET2}|sed -e 's/\s\+/\n/g'|grep subnet-|awk -F\" '{print $2}')
#echo "PRIVSUBNETID:2  ${PRIVSUBNETID2}"


# Create Public Subnet
readonly PUBLICSUBNET=$(aws ec2 create-subnet --vpc-id ${VPCID} --cidr-block 20.20.20.0/24)
readonly PUBSUBNETID=$(echo ${PUBLICSUBNET}|sed -e 's/\s\+/\n/g'|grep subnet-|awk -F\" '{print $2}')
# Ensure all systems launched in public subnet are given a public IP
aws ec2 modify-subnet-attribute --subnet-id ${PUBSUBNETID} --map-public-ip-on-launch
echo "PUBSUBNETID:  ${PUBSUBNETID}"
##############################################################
# Create Internet Gateway
IGWCREATE=`aws ec2 create-internet-gateway`
IGW=`echo ${IGWCREATE}|sed 's/\"//g'|tr ':', '\n'|grep "igw-"|sed "s/[ ]*//"`

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id ${VPCID} --internet-gateway-id ${IGW}
##############################################################
# Set up Elastic IP for the Nat Gateway
# Needed during setup for private instances to access yum repo server
# Create it
NATEIPCREATE=`aws ec2 allocate-address --domain vpc`
NATEIPALLOCATIONID=`echo $NATEIPCREATE|sed -e 's/\s\+/\n/g'|grep eipalloc-|awk -F\" '{print $2}'`

# Create NAT Gateway
# subnet-id (string)                         The private subnet in which to create the NAT gateway.
# allocation-id (string)                    The allocation ID of an Elastic IP address to associate with the NAT gateway.
NATGATEWAYCREATE=`aws ec2 create-nat-gateway --subnet-id ${PUBSUBNETID} --allocation-id ${NATEIPALLOCATIONID}`
NATGW=`echo ${NATGATEWAYCREATE}|tr ',', '\n'|grep NatGatewayId|awk -F\" '{print $4}'`

# Wait for Nat Gateway to become available
NATGWSTATE="tbd"
while [[ ${NATGWSTATE} != "available" ]] ; do
        echo "Waiting for NAT GATEWAY to become available"
        sleep 5
        NATGWSTATE=$(aws ec2 describe-nat-gateways --nat-gateway-ids ${NATGW}|grep State|awk -F\" '{print $4}')
done
##############################################################		
# Create public route table
PUBROUTETABLEIDCREATE=`aws ec2 create-route-table --vpc-id ${VPCID}`
PUBROUTETABLEID=`echo ${PUBROUTETABLEIDCREATE}|sed 's/\"//g'|tr ':', '\n'|grep "rtb-"|sed "s/[ ]*//"`

# Create private route table
PRIVROUTETABLEIDCREATE=`aws ec2 create-route-table --vpc-id ${VPCID}`
PRIVROUTETABLEID=`echo ${PRIVROUTETABLEIDCREATE}|sed 's/\"//g'|tr ':', '\n'|grep "rtb-"|sed "s/[ ]*//"`
##############################################################		
# Create routes
# Create public route for kali boxes
aws ec2 create-route --route-table-id ${PUBROUTETABLEID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW}

# Create private route for targets to reach public repo
aws ec2 create-route --route-table-id ${PRIVROUTETABLEID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${NATGW}
#aws ec2 create-route --route-table-id ${PRIVROUTETABLEID} --destination-cidr-block 34.192.172.134/32 --gateway-id ${NATGW}

##############################################################
# Associate route tables with networks
# Public
PUBROUTEASSOC=`aws ec2 associate-route-table  --subnet-id ${PUBSUBNETID} --route-table-id ${PUBROUTETABLEID}`
# Private
PRIVROUTEASSOC=`aws ec2 associate-route-table  --subnet-id ${PRIVSUBNETID} --route-table-id ${PRIVROUTETABLEID}`		


readonly PUBLICSG=$(aws ec2 create-security-group --group-name publicsg${TEAMNAME} --description "publicsg${TEAMNAME}" --vpc-id ${VPCID})
readonly PUBLICSGID=$(echo $PUBLICSG|awk -F\" '{print $4}')
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSGID} --protocol tcp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSGID} --protocol udp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSGID} --protocol icmp --port all      --cidr 0.0.0.0/0
echo "PUBLICSGID: ${PUBLICSGID}"

readonly PRIVATESG=$(aws ec2 create-security-group --group-name privatesg${TEAMNAME} --description "privatesg${TEAMNAME}" --vpc-id ${VPCID})
readonly PRIVATESGID=$(echo $PRIVATESG |awk -F\" '{print $4}')
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGID} --protocol tcp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGID} --protocol udp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGID} --protocol icmp --port all     --cidr 0.0.0.0/0

echo "TEAMNAME: $TEAMNAME"      >> ${PROPSFILE}
echo "NOW: $NOW"                >> ${PROPSFILE}
echo "BASEDIR: $BASEDIR"        >> ${PROPSFILE}
echo "SCRIPTSDIR: $SCRIPTSDIR"  >> ${PROPSFILE}
echo "TMPDIR: $TMPDIR"          >> ${LOGFILE}
echo "PROPSDIR: $PROPSDIR"      >> ${PROPSFILE}
echo "LOGDIR: $LOGDIR"          >> ${PROPSFILE}
echo "LOGFILE: $LOGFILE"        >> ${PROPSFILE}
echo "REGION: $REGION"          >> ${PROPSFILE}
echo "KEYNAME: $KEYNAME"        >> ${PROPSFILE}
echo "INSTANCETYPECENTOS: $INSTANCETYPECENTOS"   >> ${PROPSFILE}
echo "INSTANCETYPEKALI: $INSTANCETYPEKALI"       >> ${PROPSFILE}
echo "INSTANCETYPEWINDOWS: $INSTANCETYPEWINDOWS" >> ${PROPSFILE}
echo "IMAGEIDCENTOS54: $IMAGEIDCENTOS54"         >> ${PROPSFILE}
echo "IMAGEIDCENTOS511: $IMAGEIDCENTOS511"       >> ${PROPSFILE}
echo "IMAGEIDCENTOS6: $IMAGEIDCENTOS6"           >> ${PROPSFILE}
echo "IMAGEIDCENTOS7: $IMAGEIDCENTOS7"           >> ${PROPSFILE}
echo "IMAGEIDUBUNTU: $IMAGEIDUBUNTU"           >> ${PROPSFILE}
echo "IMAGEIDKALI: $IMAGEIDKALI"                 >> ${PROPSFILE}
echo "VPCID: $VPCID"                    >> ${PROPSFILE}
echo "PRIVSUBNETID: $PRIVSUBNETID"      >> ${PROPSFILE}
echo "PUBSUBNETID: $PUBSUBNETID"        >> ${PROPSFILE}
echo "PUBLICSGID: $PUBLICSGID"          >> ${PROPSFILE}
echo "PRIVATESGID: $PRIVATESGID"        >> ${PROPSFILE}




# IP requirements
#       Killian's IP address needs to be in fury's /etc/hosts file
#       Fury's IP needs to be in killian's security-group for enabling rdp from fury to killian
# Solution
#       1. Create an empty security group for killian (i.e. nothing allowed)
#       2. Deploy killian with that security group
#       3. Capture killian's IP address
#       4. Deploy fury
#       5. Add killian's IP to fury's /etc/hosts file
#       6. Update the security group for killian to only allow connections from fury's IP address

# Be sure and launcg killian before fury
for SYS in killian fury hammer pepper rhodes jarvis vanko hulk romanoff kaliws1 kaliws2 kaliws3; do

	# Assign subnet, security group, and instance type
        case $SYS in
                fury | pepper | rhodes | vanko | jarvis | hulk | romanoff )
                        SUBNETID=${PRIVSUBNETID}
                        SECGROUPID=${PRIVATESGID}
                        INSTANCETYPE=${INSTANCETYPECENTOS}
                        ;;
		hammer )
			SUBNETID=${PRIVSUBNETID}
                        SECGROUPID=${PRIVATESGID}
                        INSTANCETYPE=${INSTANCETYPEUBUNTU}
			;;
		killian )
			SUBNETID=${PRIVSUBNETID}
                        SECGROUPID=${PRIVATESGID}
                        INSTANCETYPE=${INSTANCETYPEWINDOWS}
			;;
                kali* )
                        SUBNETID=${PUBSUBNETID}
                        SECGROUPID=${PUBLICSGID}
                        INSTANCETYPE=${INSTANCETYPEKALI}
                        ;;
        esac

	# Select AMI
        case $SYS in
                fury | vanko  )		                        AMIID=${IMAGEIDCENTOS7};;
                pepper | rhodes )    				AMIID=${IMAGEIDCENTOS7};;
                hulk | romanoff )	    			AMIID=${IMAGEIDCENTOS511};;
		jarvis )                                        AMIID=${IMAGEIDCENTOS54};;
                hammer )                                        AMIID=${IMAGEIDUBUNTU};;
                killian )                                       AMIID=${IMAGEIDWINDOWS};;
                kali* )                                         AMIID=${IMAGEIDKALI};;
        esac


	# Select userdata script
        case $SYS in
                fury )          USERDATASCRIPT=${USERDATADIR}/furyuserdata.txt ;;
                hammer )        USERDATASCRIPT=${USERDATADIR}/ubuntuuserdata.txt ;;
                pepper )        USERDATASCRIPT=${USERDATADIR}/pepperuserdata.txt ;;
                rhodes )        USERDATASCRIPT=${USERDATADIR}/rhodesuserdata.txt ;;
                vanko )         USERDATASCRIPT=${USERDATADIR}/vankouserdata.txt ;;
                jarvis )        USERDATASCRIPT=${USERDATADIR}/jarvisuserdata.txt ;;
                hulk )          USERDATASCRIPT=${USERDATADIR}/hulkuserdata.txt ;;
                romanoff )      USERDATASCRIPT=${USERDATADIR}/romanoffuserdata.txt ;;
                kaliws1 )       USERDATASCRIPT=${USERDATADIR}/kaliws1userdata.txt ;;
                kaliws2 )       USERDATASCRIPT=${USERDATADIR}/kaliws2userdata.txt ;;
                kaliws3 )       USERDATASCRIPT=${USERDATADIR}/kaliws3userdata.txt ;;
                killian )       USERDATASCRIPT=${USERDATADIR}/killianuserdata.txt ;;
        esac


	case $SYS in
                fury | pepper | rhodes | vanko | jarvis | hulk | romanoff )
			cat commonuserdata.txt | sed "s/REPLACEROLENAME/$SYS/" > ${USERDATASCRIPT}
			;;
		hammer )
			cat ubuntuuserdata.txt | sed "s/REPLACEROLENAME/$SYS/" > ${USERDATASCRIPT}
			;;
	esac

	# Killian is a Windows box and does not need/get userdata
	if [ $SYS == "killian" ] ; then

	  # Create security group for Killian
	  readonly PRIVATESGWIN=$(aws ec2 create-security-group --group-name privatesgwin${TEAMNAME} --description "privatesgwin${TEAMNAME}" --vpc-id ${VPCID})
	  readonly PRIVATESGIDWIN=$(echo $PRIVATESGWIN |awk -F\" '{print $4}')

	   # Launch windows instance
           NEWINSTANCEID=`aws ec2 --region=${REGION} run-instances --image-id ${AMIID} \\
                --key-name ${KEYNAME} \\
                --instance-type ${INSTANCETYPE} \\
                --security-group-ids ${PRIVATESGIDWIN}  \\
                --subnet-id ${SUBNETID} \\
                --count 1`

	   INSTANCEID=`echo $NEWINSTANCEID|sed 's/\"//g'|tr ',' '\n'|grep InstanceId|awk -F\: '{print $2}'|sed "s/[ ]*//"`

	   KILLIANIP=`aws ec2 describe-instances --instance-id ${INSTANCEID}|grep PrivateIpAddress\"|sed "s/[ ]*//"|awk -F\" '{print $4}'|sort|uniq|head -1`
	

	elif [ $SYS == "fury" ] ; then
	   TMPFILE=$(/bin/mktemp)
	   cat ${USERDATASCRIPT} | sed "s/REPLACEKILLIANIP/$KILLIANIP/" > ${TMPFILE}
	   cp ${TMPFILE} ${USERDATASCRIPT}

           NEWINSTANCEID=`aws ec2 --region=${REGION} run-instances --image-id ${AMIID} \\
                --key-name ${KEYNAME} \\
                --instance-type ${INSTANCETYPE} \\
                --security-group-ids ${SECGROUPID}  \\
                --subnet-id ${SUBNETID} \\
                --count 1 \\
                --user-data file://${USERDATASCRIPT}`

	   INSTANCEID=`echo $NEWINSTANCEID|sed 's/\"//g'|tr ',' '\n'|grep InstanceId|awk -F\: '{print $2}'|sed "s/[ ]*//"`
	   FURYIP=`aws ec2 describe-instances --instance-id ${INSTANCEID}|grep PrivateIpAddress\"|sed "s/[ ]*//"|awk -F\" '{print $4}'|sort|uniq|head -1`
	   # modify secuirty group for killian (Windows) VM to only allow connections from fury's IP.
           aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGIDWIN} --protocol tcp  --port 0-65535 --cidr ${FURYIP}/32
           aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGIDWIN} --protocol udp  --port 0-65535 --cidr ${FURYIP}/32
           aws ec2 authorize-security-group-ingress --group-id ${PRIVATESGIDWIN} --protocol icmp --port all     --cidr ${FURYIP}/32




	else
           NEWINSTANCEID=`aws ec2 --region=${REGION} run-instances --image-id ${AMIID} \\
                --key-name ${KEYNAME} \\
                --instance-type ${INSTANCETYPE} \\
                --security-group-ids ${SECGROUPID}  \\
                --subnet-id ${SUBNETID} \\
                --count 1 \\
                --user-data file://${USERDATASCRIPT}`

	fi


        INSTANCEID=`echo $NEWINSTANCEID|sed 's/\"//g'|tr ',' '\n'|grep InstanceId|awk -F\: '{print $2}'|sed "s/[ ]*//"`

        echo "deploying INSTANCEID: ${SYS} ${INSTANCEID}"

        echo "INSTANCEID${SYS}: ${INSTANCEID}" >> ${PROPSFILE}


done

echo "waiting for systems to launch"
sleep 20


# Assign VPC Name
aws ec2 create-tags --resources ${VPCID} --tags "Key=Name,Value=$TEAMNAME-$NOW"

# Assign network names
aws ec2 create-tags --resource ${PUBSUBNETID}  --tags "Key=Name,Value=${TEAMNAME}-Public subnet-${NOW}"
aws ec2 create-tags --resource ${PRIVSUBNETID} --tags "Key=Name,Value=${TEAMNAME}-Private subnet1-${NOW}"
#aws ec2 create-tags --resource ${PRIVSUBNETID2} --tags "Key=Name,Value=${TEAMNAME}-Private subnet2-${NOW}"

# Assign EC2 Instance Names
for SYS in $(grep ^INSTANCEID $PROPSFILE | awk -F\: '{print $1}' | sed "s/INSTANCEID//") ; do

        echo $SYS

        INSTANCEID=$(grep ^INSTANCEID${SYS} ${PROPSFILE} | awk -F\: '{print $2}'||sed "s/[ ]*//")
        ROLE=$(grep ${SYS} ${PROPSFILE} | awk -F\: '{print $1}'|sed "s/INSTANCEID//")

        echo "ROLE: ${ROLE}"
        echo "INSTANCEID: $INSTANCEID"

        aws ec2 --region=us-east-1 create-tags --resources ${INSTANCEID} --tags Key=Name,Value=${TEAMNAME}-${ROLE}-${NOW}

done

