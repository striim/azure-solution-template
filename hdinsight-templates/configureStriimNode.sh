#!/bin/bash


STRIIM_VERSION="3.8.3-wc-hd-PreRelease";
STRIIM_DBMS_DEB_URI="https://striim-downloads.s3.amazonaws.com/striim-dbms-$STRIIM_VERSION-Linux.deb";
STRIIM_SAMPLEDB_URI="https://striim-downloads.s3.amazonaws.com/SampleAppsDB-$STRIIM_VERSION.tgz";
STRIIM_NODE_DEB_URI="https://striim-downloads.s3.amazonaws.com/striim-node-$STRIIM_VERSION-Linux.deb";
STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;

#We might not need all these parameters
#but it is good to save all these as these are the parameters passed to 
# the custom script

edgeNodePrefix=$1
resourceGroupName=$2
subscriptionId=$3
subscriptionTenantId=$4

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
    echo "HDInsight cluster Name=$CLUSTERNAME"
}

checkJava() {
	if [[ $OS_VERSION == 14* ]]; then
		export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
	elif [[ $OS_VERSION == 16* ]]; then
		export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
	fi
    echo "Java Home set to $JAVA_HOME"
}

checkNodeJs() {
  if ! [ -x "$(command -v npm)" ]; then
      curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
      apt-get install -y nodejs
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
    echo "Going to install Striim as root user..."
}


downloadAndInstallStriim() {
    echo "Downloading striim-dbms..."
    wget -q --no-check-certificate $STRIIM_DBMS_DEB_URI || errorExit "Could not find dbms deb"
    dpkg -i striim-dbms-$STRIIM_VERSION-Linux.deb || errorExit "Could not install dbms deb"
    rm -rf striim-dbms-$STRIIM_VERSION-Linux.deb
    echo "Installed striim-dbms"
        
    echo "Downloading striim-samples..."
    wget -q --no-check-certificate $STRIIM_SAMPLEDB_URI
    if [ $? -eq 0 ]; then
        tar xzf "SampleAppsDB-$STRIIM_VERSION.tgz" && rm -rf /var/striim/wactionrepos && mv wactionrepos /var/striim/
        rm -rf "SampleAppsDB-$STRIIM_VERSION.tgz"
    fi
    echo "Installed striim-samples"
    
    echo "Downloading striim-node..."
    wget -q --no-check-certificate $STRIIM_NODE_DEB_URI || errorExit "Could not find node deb"
    dpkg -i striim-node-$STRIIM_VERSION-Linux.deb || errorExit "Could not install node deb"
    rm -rf striim-node-$STRIIM_VERSION-Linux.deb
    
    STRIIM_CONF_FILE=`find /opt/ -name striim.conf`;
    [ -f $STRIIM_CONF_FILE ] || errorExit "Striim could not be installed"	

    echo "Installed striim-node"
}

configureStriim() {
    rm $STRIIM_CONF_FILE
}

setupStriimService() {
    echo "Configuring Striim as a systemd service" 
    chown -R striim:striim /var/striim
    chown -R striim:striim /opt/striim
    systemctl daemon-reload
    systemctl enable striim-dbms
    systemctl enable striim-node
    systemctl enable striim-webconfig
    systemctl start striim-dbms
    systemctl start striim-webconfig
    echo "Striim service started"
}



checkJava
checkIfRootUser
checkHostNameAndSetClusterName
checkNodeJs
downloadAndInstallStriim
configureStriim
setupStriimService

