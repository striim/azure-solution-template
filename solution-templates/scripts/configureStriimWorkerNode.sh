#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <FQDN> <MASTER_NODE_FQDN> <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD>
#  
#
###################################################

STRIIM_VERSION="3.8.4";
node_rpm="striim-node-$STRIIM_VERSION-Linux.rpm"
samples_rpm="striim-samples-$STRIIM_VERSION-Linux.rpm"

AZURE_STRIIM_DOWNLOADS="https://striimreleases.blob.core.windows.net/striimreleases/$STRIIM_VERSION/"
NODE_PATH=$AZURE_STRIIM_DOWNLOADS$node_rpm
SAMPLESDATA_PATH=$AZURE_STRIIM_DOWNLOADS$samples_rpm


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
MASTER_NODE_PRIVATE_INTERFACE="$1"
shift
VM_IP_ADDRESS=`hostname -i`

function errorExit() {
    echo "ERROR: $1"
    exit 1;
}

function installStriim() {
	echo "Installing node rpm in worker node"
    wget -q --no-check-certificate $NODE_PATH -O $node_rpm || errorExit "Could not find node rpm"
    rpm -i -v $node_rpm
    rm -rf $node_rpm

	echo "Installing Samples data folder in worker node"
    wget -q --no-check-certificate $SAMPLESDATA_PATH -O $samples_rpm || errorExit "Could not find Samples data rpm"
    rpm -i -v $samples_rpm
    rm -rf $samples_rpm
}

function getLocalInterfaceIp() {
    for seq in `seq 20`; do
       IP_ADDR=`hostname -i`
       if [ $IP_ADDR != "" ]; then
           eval "$1=$IP_ADDR"
           return 0
       fi
       /bin/sleep 1
    done
    /bin/logger -t striim-node "Cannot start as local interface IP address is not available"
    exit 1
}

configureStriim() {

PASSWORD_ENCRYPTOR_FILE=`find /opt/ -name passwordEncryptor.sh`;
[[ -f $PASSWORD_ENCRYPTOR_FILE ]] || errorExit "Striim Server not installed properly. Missing passwordEncryptor.sh"

STARTUP_PROPERTIES_FILE=/opt/striim/conf/startUp.properties
source /etc/striim/product.conf
getLocalInterfaceIp WA_IP_ADDRESS
WA_CLUSTER_PASSWORD=`$PASSWORD_ENCRYPTOR_FILE $CLUSTER_PASSWORD`
WA_ADMIN_PASSWORD=`$PASSWORD_ENCRYPTOR_FILE $ADMIN_PASSWORD`
WA_NODE_PUBLIC_IP=`dig +short ${VM_FQDN}`

echo "WAClusterName=$CLUSTER_NAME" > $STARTUP_PROPERTIES_FILE
echo "CompanyName=AzureCompany" >> $STARTUP_PROPERTIES_FILE
echo "Interfaces=$WA_IP_ADDRESS"  >> $STARTUP_PROPERTIES_FILE
echo "WAClusterPassword=$WA_CLUSTER_PASSWORD" >> $STARTUP_PROPERTIES_FILE
echo "WAAdminPassword=$WA_ADMIN_PASSWORD" >> $STARTUP_PROPERTIES_FILE
echo "ProductKey=$WA_PRODUCT_KEY" >> $STARTUP_PROPERTIES_FILE
echo "LicenceKey=$WA_LICENSE_KEY" >> $STARTUP_PROPERTIES_FILE
echo "DeploymentGroups=default" >> $STARTUP_PROPERTIES_FILE
echo "ServerFqdn=$VM_FQDN" >> $STARTUP_PROPERTIES_FILE
echo "NodePublicAddress=$WA_NODE_PUBLIC_IP" >> $STARTUP_PROPERTIES_FILE
echo "ServerNodeAddress=$MASTER_NODE_FQDN" >> $STARTUP_PROPERTIES_FILE
echo "IsTcpIpCluster=true" >> $STARTUP_PROPERTIES_FILE
echo "MetaDataRepositoryLocation=$MASTER_NODE_PRIVATE_INTERFACE" >> $STARTUP_PROPERTIES_FILE

cat << EFHOST > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${VM_IP_ADDRESS} ${VM_FQDN}
EFHOST

cat << 'EOF' > /opt/Striim/conf/log4j.console.properties
log4j.rootLogger=warn, R

# output to the terminal
log4j.appender.stdout=org.apache.log4j.ConsoleAppender

log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d - %p %t %C.%M (%F:%L) %m%n


# output to log file
log4j.appender.R=org.apache.log4j.RollingFileAppender
log4j.appender.R.File=${user.home}/striim.console.log
log4j.appender.R.MaxFileSize=100KB
log4j.appender.R.MaxBackupIndex=1

log4j.appender.R.layout=org.apache.log4j.PatternLayout
log4j.appender.R.layout.ConversionPattern=%d - %p %t %C.%M (%F:%L) %m%n



# package/class logging level
#log4j.logger.com.webaction.security.WASecurityManager=TRACE
#log4j.logger.com.webaction.metaRepository.MDCache=TRACE
#log4j.logger.com.webaction.tungsten.Tungsten=TRACE
EOF
}

setupStriimService() {
    echo "Configuring Striim as a systemd service" 
    chown -R striim:striim /opt/striim   
    systemctl daemon-reload
    systemctl enable striim-node
    systemctl start striim-node
    echo "Striim service started" 
}

installStriim
configureStriim
setupStriimService


