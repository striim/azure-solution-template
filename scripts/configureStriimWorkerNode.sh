#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <FQDN> <MASTER_NODE_FQDN> <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD> <PRODUCT KEY> <LICENSE KEY>
#  
#
###################################################

STRIIM_VERSION="3.6.8-azure-sols10-PreRelease";

VM_FQDN="$1"
shift
MASTER_NODE_FQDN="$1"
shift
COMPANY_NAME="$1"
shift 
CLUSTER_NAME="$1" 
shift
CLUSTER_PASSWORD="$1" 
shift
ADMIN_PASSWORD="$1" 
shift
PRODUCT_KEY="$1" 
shift
LICENSE_KEY="$1"    
shift

function errorExit() {
    echo "ERROR: $1"
    exit 1;
}

function installStriim() {
    
    wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.rpm" || errorExit "Could not find node rpm"
    rpm -i -v striim-node-$STRIIM_VERSION-Linux.rpm 
    rm -rf striim-node-$STRIIM_VERSION-Linux.rpm
    
}

installStriim

STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

[[ -f $STRIIM_CONF_FILE ]] || errorExit "Striim Server not installed" 


cat << EOF > $STRIIM_CONF_FILE
WA_VERSION="$STRIIM_VERSION"
WA_HOME="/opt/Striim-$STRIIM_VERSION"
WA_START="Service"
WA_CLUSTER_NAME="$CLUSTER_NAME"
WA_CLUSTER_PASSWORD="$CLUSTER_PASSWORD"
WA_ADMIN_PASSWORD="$ADMIN_PASSWORD"
WA_PRODUCT_KEY="$PRODUCT_KEY"
WA_LICENSE_KEY="$LICENSE_KEY"
WA_COMPANY_NAME="AzureCompany"
WA_DEPLOYMENT_GROUPS="default"
WA_SERVER_FQDN="$VM_FQDN"
WA_MASTER_NODE_FQDN="$MASTER_NODE_FQDN"
EOF

cat << 'EOF' >> $STRIIM_CONF_FILE
WA_IP_ADDRESS=`ifconfig |grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}'`
WA_NODE_PUBLIC_IP=`dig +short ${WA_SERVER_FQDN}`

WA_OPTS="-c ${WA_CLUSTER_NAME} -p ${WA_CLUSTER_PASSWORD} -i ${WA_IP_ADDRESS} -a ${WA_ADMIN_PASSWORD}  -N "${WA_COMPANY_NAME}" -G ${WA_DEPLOYMENT_GROUPS} -P ${WA_PRODUCT_KEY} -L ${WA_LICENSE_KEY} -t True -d ${WA_MASTER_NODE_FQDN} -f ${WA_SERVER_FQDN} -q ${WA_NODE_PUBLIC_IP}"

cat << EFHOST > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${WA_IP_ADDRESS} ${WA_SERVER_FQDN}
EFHOST

EOF


start striim-node;



