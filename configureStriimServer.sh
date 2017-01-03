#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD> [<PRODUCT KEY> <LICENSE KEY>]
#  
#
###################################################

STRIIM_VERSION="3.6.7-azure-ui-fixes-PreRelease";

function errorExit() {
    echo "Exiting: $1"
    exit 1;
}

function installStriim() {
    wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-dbms-$STRIIM_VERSION-Linux.rpm"
    wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.rpm"
    rpm -i -v striim-dbms-$STRIIM_VERSION-Linux.rpm 
    rpm -i -v striim-node-$STRIIM_VERSION-Linux.rpm 
    rm -rf striim-dbms-$STRIIM_VERSION-Linux.rpm
    rm -rf striim-node-$STRIIM_VERSION-Linux.rpm
}

installStriim

STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

[[ -f $STRIIM_CONF_FILE ]] || errorExit "Striim Server not installed" 

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
localIpAddress=`ifconfig |grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}'`

rm $STRIIM_CONF_FILE
cat << EOF >> $STRIIM_CONF_FILE
WA_VERSION="3.6.7"
WA_HOME="/opt/Striim-3.6.7"
WA_START="Service"
WA_CLUSTER_NAME="AzureCompany"
WA_CLUSTER_PASSWORD="$CLUSTER_PASSWORD"
WA_ADMIN_PASSWORD="$ADMIN_PASSWORD"
WA_IP_ADDRESS="$localIpAddress"
WA_PRODUCT_KEY="$PRODUCT_KEY"
WA_LICENSE_KEY="$LICENSE_KEY"
WA_COMPANY_NAME="AzureCompany"
WA_DEPLOYMENT_GROUPS="default"
EOF

cat << 'EOF' >> $STRIIM_CONF_FILE
WA_OPTS="-c ${WA_CLUSTER_NAME} -p ${WA_CLUSTER_PASSWORD} -i ${WA_IP_ADDRESS} -a ${WA_ADMIN_PASSWORD}  -N "${WA_COMPANY_NAME}" -G ${WA_DEPLOYMENT_GROUPS} -P ${WA_PRODUCT_KEY} -L ${WA_LICENSE_KEY}"

export JAVA_SYSTEM_PROPERTIES="-Dcom.webaction.config.enable-tcpipClustering=True -Dcom.webaction.config.servernode.address=${WA_IP_ADDRESS}"
EOF

stop striim-dbms;
stop striim-node;
start striim-dbms;
start striim-node;



