#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD> [<PRODUCT KEY> <LICENSE KEY>]
#  
#
###################################################



function installStriim() {
    wget --no-check-certificate 'https://striim-downloads.s3.amazonaws.com/striim-dbms-3.6.7-Linux.rpm'
    wget --no-check-certificate 'https://striim-downloads.s3.amazonaws.com/striim-node-3.6.7-Linux.rpm'
    rpm -i -v striim-dbms-3.6.7-Linux.rpm 
    rpm -i -v striim-node-3.6.7-Linux.rpm 
    rm -rf striim-dbms-3.6.7-Linux.rpm
    rm -rf striim-node-3.6.7-Linux.rpm
}

installStriim

STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

function modifyStriimConfig() {
    configName=$1;
    configValue=$2;

    if  [ -z "$configName" ]; then
        return;
    fi
    if  [ -n "$configValue" ]; then
        sed -i.bak -r "s/($configName *= *\").*/\1$configValue\"/" $STRIIM_CONF_FILE;        
    fi
}

for config in "WA_COMPANY_NAME" "WA_CLUSTER_NAME" "WA_CLUSTER_PASSWORD" "WA_ADMIN_PASSWORD" "WA_PRODUCT_KEY" "WA_LICENSE_KEY"; 
do
    configValue="$1";
    shift;
    modifyStriimConfig $config $configValue;
done

localIpAddress=`ifconfig |grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}'`
modifyStriimConfig WA_IP_ADDRESS $localIpAddress

stop striim-dbms;
stop striim-node;
start striim-dbms;
start striim-node;

