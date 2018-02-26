#!/bin/bash

###################################################
# Configures Striim Server and restarts 
#
# Usage:
#  $ ./configureStriimServer.sh <FQDN> <COMPANY_NAME> <CLUSTER NAME> <CLUSTER PASSWORD> <ADMIN PASSWORD>
#  
#
###################################################

STRIIM_VERSION="3.8.2A";

VM_FQDN="$1"
shift
COMPANY_NAME="$1"
shift 
CLUSTER_NAME="$1" 
shift
CLUSTER_PASSWORD="$1" 
shift
ADMIN_PASSWORD="$1" 
shift
VM_IP_ADDRESS=`hostname -i`

function errorExit() {
    echo "ERROR: $1"
    exit 1;
}

function installStriim() {
	echo "Installing MDR"
    wget -q --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-dbms-$STRIIM_VERSION-Linux.rpm" || errorExit "Could not find dbms rpm"
    rpm -i -v striim-dbms-$STRIIM_VERSION-Linux.rpm 
    rm -rf striim-dbms-$STRIIM_VERSION-Linux.rpm
    
	echo "Installing Sample Apps"    
    wget -q --no-check-certificate "https://striim-downloads.s3.amazonaws.com/SampleAppsDB-$STRIIM_VERSION.tgz"
    if [ $? -eq 0 ]; then
        tar xzf "SampleAppsDB-$STRIIM_VERSION.tgz" && rm -rf /var/striim/wactionrepos && mv wactionrepos /var/striim/
        rm -rf "SampleAppsDB-$STRIIM_VERSION.tgz"
    fi
    
	echo "Installing node"
    wget -q --no-check-certificate "https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.rpm" || errorExit "Could not find node rpm"
    rpm -i -v striim-node-$STRIIM_VERSION-Linux.rpm 
    rm -rf striim-node-$STRIIM_VERSION-Linux.rpm
    
	STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;
	[[ -f $STRIIM_CONF_FILE ]] || errorExit "Striim Server not installed" 
	ln -s /var/striim/Samples /opt/striim/Samples
}


configureStriim() {
cat << 'EOF' > $STRIIM_CONF_FILE
function getLocalInterfaceIp() {
    for seq in `seq 20`; do
       IP_ADDR=`hostname -i`
       if [ $IP_ADDR != "" ]; then
           WA_IP_ADDRESS=$IP_ADDR
           return 0
       fi
       /bin/sleep 1
    done
    /bin/logger -t striim-node "Cannot start as local interface IP address is not available"
    exit 1
}

getLocalInterfaceIp
EOF

cat << EOF >> $STRIIM_CONF_FILE

WA_VERSION="$STRIIM_VERSION"
WA_HOME="/opt/striim"
WA_START="Service"
WA_CLUSTER_NAME="$CLUSTER_NAME"
WA_CLUSTER_PASSWORD="$CLUSTER_PASSWORD"
WA_ADMIN_PASSWORD="$ADMIN_PASSWORD"
WA_COMPANY_NAME="AzureCompany"
WA_DEPLOYMENT_GROUPS="default"
WA_SERVER_FQDN="$VM_FQDN"
EOF

cat /etc/striim/product.conf >> $STRIIM_CONF_FILE

cat << 'EOF' >> $STRIIM_CONF_FILE
WA_NODE_PUBLIC_IP=`dig +short ${WA_SERVER_FQDN}`

WA_OPTS="-c ${WA_CLUSTER_NAME} -p ${WA_CLUSTER_PASSWORD} -i ${WA_IP_ADDRESS} -a ${WA_ADMIN_PASSWORD}  -N "${WA_COMPANY_NAME}" -G ${WA_DEPLOYMENT_GROUPS} -P ${WA_PRODUCT_KEY} -L ${WA_LICENSE_KEY} -t True -d ${WA_NODE_PUBLIC_IP} -f ${WA_SERVER_FQDN} -q ${WA_NODE_PUBLIC_IP}"
EOF


cat << EFHOST > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${VM_IP_ADDRESS} ${VM_FQDN}
EFHOST

cat << 'EOF' > /opt/striim/conf/log4j.console.properties
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
    chown -R striim:striim /var/striim
    chown -R striim:striim /opt/striim   
    systemctl daemon-reload
    systemctl enable striim-dbms
    systemctl enable striim-node
    systemctl start striim-dbms
    systemctl start striim-node
    echo "Striim service started" 
}



installStriim
configureStriim
setupStriimService


