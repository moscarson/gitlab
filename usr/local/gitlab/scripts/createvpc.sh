#! /bin/bash
# createvpc.sh
# AWS supports assigning EC2 instance tags on creation.  Other items will need to be parsed and determined manually

if [ $# -ne 1 ] ; then
  echo "Usage:  $0  vpcname"
  exit 1
fi

readonly VPCNAME=$1

readonly REGION="us-east-1"
readonly PUBKEYNAME="forge-mil-nat"
readonly PRIVKEYNAME="forge-mil-sut"
readonly INSTANCETYPETEMP="t2.micro"

##############################################################		
# Create VPC
VPCTEMP=$(aws ec2 create-vpc --cidr-block 20.20.0.0/16)
VPCID=$(echo ${VPCTEMP}| sed -e 's/\s\+/\n/g'|grep -v vpc-cidr-assoc|grep ^vpc)

##############################################################		
# Create subnets
# Create Private Subnet1
readonly PRIVATESUBNET=$(aws ec2 create-subnet --vpc-id ${VPCID} --cidr-block 20.20.10.0/24)
readonly PRIVSUBNETID=$(echo ${PRIVATESUBNET}|sed -e 's/\s\+/\n/g'|grep ^subnet)
echo "PRIVSUBNETID:  ${PRIVSUBNETID}"

# Create Public Subnet
readonly PUBLICSUBNET=$(aws ec2 create-subnet --vpc-id ${VPCID} --cidr-block 20.20.20.0/24)
readonly PUBSUBNETID=$(echo ${PUBLICSUBNET}|sed -e 's/\s\+/\n/g'|grep ^subnet)
# Ensure all systems launched in public subnet are given a public IP
aws ec2 modify-subnet-attribute --subnet-id ${PUBSUBNETID} --map-public-ip-on-launch
echo "PUBSUBNETID:  ${PUBSUBNETID}"

# Create Internet Gateway
IGWCREATE=`aws ec2 create-internet-gateway`
IGW=$(echo ${IGWCREATE}|sed -e 's/\s\+/\n/g'|grep ^igw)

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id ${VPCID} --internet-gateway-id ${IGW}

##############################################################		
# Create public route table
PUBROUTETABLEIDCREATE=`aws ec2 create-route-table --vpc-id ${VPCID}`
PUBROUTETABLEID=$(echo ${PUBROUTETABLEIDCREATE}|sed -e 's/\s\+/\n/g'|grep ^rtb)

# Create private route table
PRIVROUTETABLEIDCREATE=`aws ec2 create-route-table --vpc-id ${VPCID}`
PRIVROUTETABLEID=$(echo ${PRIVROUTETABLEIDCREATE}|sed -e 's/\s\+/\n/g'|grep ^rtb)

##############################################################		
# Create routes
# Create public route for instances on public subnet
aws ec2 create-route --route-table-id ${PUBROUTETABLEID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW}

##############################################################
# Associate route tables with networks
# Public
PUBROUTEASSOC=`aws ec2 associate-route-table  --subnet-id ${PUBSUBNETID} --route-table-id ${PUBROUTETABLEID}`
# Private
PRIVROUTEASSOC=`aws ec2 associate-route-table  --subnet-id ${PRIVSUBNETID} --route-table-id ${PRIVROUTETABLEID}`		

readonly PUBLICSG=$(aws ec2 create-security-group --group-name publicsg${VPCNAME} --description "publicsg${VPCNAME}" --vpc-id ${VPCID})
readonly PUBLICSG=$(echo $PUBLICSG|awk -F\" '{print $4}')
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSG} --protocol tcp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSG} --protocol udp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PUBLICSG} --protocol icmp --port all      --cidr 0.0.0.0/0
echo "PUBLICSGID: ${PUBLICSGID}"

readonly PRIVATESG=$(aws ec2 create-security-group --group-name privatesg${VPCNAME} --description "privatesg${VPCNAME}" --vpc-id ${VPCID})
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESG} --protocol tcp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESG} --protocol udp  --port 0-65535 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PRIVATESG} --protocol icmp --port all     --cidr 0.0.0.0/0


