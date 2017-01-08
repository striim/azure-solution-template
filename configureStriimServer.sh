#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <INDEX> <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD> [<PRODUCT KEY> <LICENSE KEY>]
#  
#
###################################################

STRIIM_VERSION="3.6.7-azure-ui-fixes-PreRelease";

VM_INDEX="$1"
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
    if [ $VM_INDEX -eq "0" ]; then
        wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-dbms-$STRIIM_VERSION-Linux.rpm"
        rpm -i -v striim-dbms-$STRIIM_VERSION-Linux.rpm 
        rm -rf striim-dbms-$STRIIM_VERSION-Linux.rpm
        
        wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/SampleAppsDB-$STRIIM_VERSION.tgz"
        tar xzf "SampleAppsDB-$STRIIM_VERSION.tgz"
        rm -rf /var/striim/wactionrepos
        mv wactionrepos /var/striim/
        rm -rf "SampleAppsDB-$STRIIM_VERSION.tgz"
    fi
    
    wget --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.rpm"
    rpm -i -v striim-node-$STRIIM_VERSION-Linux.rpm 
    rm -rf striim-node-$STRIIM_VERSION-Linux.rpm
    
}

installStriim

STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

[[ -f $STRIIM_CONF_FILE ]] || errorExit "Striim Server not installed" 

localIpAddress=`ifconfig |grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}'`

rm $STRIIM_CONF_FILE
cat << EOF >> $STRIIM_CONF_FILE
WA_VERSION="$STRIIM_VERSION"
WA_HOME="/opt/Striim-$STRIIM_VERSION"
WA_START="Service"
WA_CLUSTER_NAME="$CLUSTER_NAME"
WA_CLUSTER_PASSWORD="$CLUSTER_PASSWORD"
WA_ADMIN_PASSWORD="$ADMIN_PASSWORD"
WA_IP_ADDRESS="$localIpAddress"
WA_PRODUCT_KEY="$PRODUCT_KEY"
WA_LICENSE_KEY="$LICENSE_KEY"
WA_COMPANY_NAME="AzureCompany"
WA_DEPLOYMENT_GROUPS="default"
EOF

cat << 'EOF' >> $STRIIM_CONF_FILE
WA_OPTS="-c ${WA_CLUSTER_NAME} -p ${WA_CLUSTER_PASSWORD} -i ${WA_IP_ADDRESS} -a ${WA_ADMIN_PASSWORD}  -N "${WA_COMPANY_NAME}" -G ${WA_DEPLOYMENT_GROUPS} -P
${WA_PRODUCT_KEY} -L ${WA_LICENSE_KEY} -t True -d 10.0.0.4,${WA_IP_ADDRESS}"

EOF

stop striim-dbms;
stop striim-node;
start striim-dbms;
start striim-node;



