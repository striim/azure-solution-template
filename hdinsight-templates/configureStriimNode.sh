#!/bin/bash


STRIIM_VERSION="3.7.4";
STRIIM_DBMS_DEB_URI="https://striim-downloads.s3.amazonaws.com/striim-dbms-$STRIIM_VERSION-Linux.deb";
STRIIM_SAMPLEDB_URI="https://striim-downloads.s3.amazonaws.com/SampleAppsDB-$STRIIM_VERSION.tgz";
STRIIM_NODE_DEB_URI="https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.deb";
STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

function errorExit() {
    echo "ERROR: $1"
    exit 1;
}

checkHostNameAndSetClusterName() {
    fullHostName=$(hostname -f)
    echo "fullHostName=$fullHostName"
    CLUSTERNAME=$(sed -n -e 's/.*\.\(.*\)-ssh.*/\1/p' <<< $fullHostName)
    if [ -z "$CLUSTERNAME" ]; then
        CLUSTERNAME=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().deployment.cluster_name" | python)
        if [ $? -ne 0 ]; then
            echo "[ERROR] Cannot determine cluster name. Exiting!"
            exit 133
        fi
    fi
    echo "Cluster Name=$CLUSTERNAME"
}

checkJava() {
	if [[ $OS_VERSION == 14* ]]; then
		export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
	elif [[ $OS_VERSION == 16* ]]; then
		export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
	fi
}

checkIfRootUser() {

	if [ "$(id -u)" != "0" ]; then
		errorExit "This script has to be run as root."
	fi

	if [ ! -z  $STRIIM_CONF_FILE && -f $STRIIM_CONF_FILE ]; then
		echo "Striim is already installed. Exiting ..."
		exit 0
	fi
}


downloadAndInstallStriim() {
    wget --no-check-certificate $STRIIM_DBMS_DEB_URI || errorExit "Could not find dbms deb"
    dpkg -i striim-dbms-$STRIIM_VERSION-Linux.deb || errorExit "Could not install dbms deb"
    rm -rf striim-dbms-$STRIIM_VERSION-Linux.deb
        
    wget --no-check-certificate $STRIIM_SAMPLEDB_URI
    if [ $? -eq 0 ]; then
        tar xzf "SampleAppsDB-$STRIIM_VERSION.tgz" && rm -rf /var/striim/wactionrepos && mv wactionrepos /var/striim/
        rm -rf "SampleAppsDB-$STRIIM_VERSION.tgz"
    fi
    
    wget --no-check-certificate $STRIIM_NODE_DEB_URI || errorExit "Could not find node deb"
    dpkg -i striim-node-$STRIIM_VERSION-Linux.deb || errorExit "Could not install node deb"
    rm -rf striim-node-$STRIIM_VERSION-Linux.deb
    
    STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;
    [ -f $STRIIM_CONF_FILE] || errorExit "Striim could not be installed"	

    echo "Installed striim-dbms and striim-node"
}

configureStriim() {
    cat << 'EOF' > $STRIIM_CONF_FILE
    function getLocalInterfaceIp() {
    for seq in `seq 20`; do
        IP_ADDR=`ifconfig |grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}'`
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
WA_HOME="/opt/Striim-$STRIIM_VERSION"
WA_START="Service"
WA_CLUSTER_NAME="$CLUSTERNAME"
WA_CLUSTER_PASSWORD="strmhdinsight"
WA_ADMIN_PASSWORD="strmadmin"
WA_COMPANY_NAME="AzureCompany"
WA_DEPLOYMENT_GROUPS="default"
WA_SERVER_FQDN=`hostname -f`
WA_PRODUCT_KEY="F7BDD4D28-8CE044FBB-687399E7"
WA_LICENSE_KEY="A41E5A6E8-E98C6797D-E97281F50-256CB886E-5D6C8AA23-D10CC"
EOF


cat << 'EOF' >> $STRIIM_CONF_FILE
WA_NODE_PUBLIC_IP=`dig +short ${WA_SERVER_FQDN}`

WA_OPTS="-c ${WA_CLUSTER_NAME} -p ${WA_CLUSTER_PASSWORD} -i ${WA_IP_ADDRESS} -a ${WA_ADMIN_PASSWORD}  -N "${WA_COMPANY_NAME}" -G ${WA_DEPLOYMENT_GROUPS} -P ${WA_PRODUCT_KEY} -L ${WA_LICENSE_KEY} -t True -d ${WA_NODE_PUBLIC_IP} -f ${WA_SERVER_FQDN} -q ${WA_NODE_PUBLIC_IP}"

EOF
}

setupStriimService() {
 
    systemctl enable striim-dbms
    systemctl enable striim-node
    ln -s /lib/systemd/system/striim-dbms.service  /etc/systemd/system/multi-user.target.wants/striim-dbms.service
    ln -s /lib/systemd/system/striim-node.service  /etc/systemd/system/multi-user.target.wants/striim-node.service
    systemctl start striim-node
}


checkJava
checkIfRootUser
checkHostNameAndSetClusterName
downloadAndInstallStriim
configureStriim
setupStriimService

