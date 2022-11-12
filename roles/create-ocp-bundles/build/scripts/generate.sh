#!/bin/bash
# Maintained by SPO <spo@redhat.com>

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
function log {
    if [ -z "$2" ]; then
	echo -e "\033[1;36m$1\033[0m"
    else
	echo -e $1 "\033[1;36m$2\033[0m"
    fi
}

function usage() {
  log "This script requires the following packages:"
  log "oc - Used to pull supporting images"
  log "podman - Used to pull supporting images"
  log "wget - Used to retrieve/download RHCOS and OC distributions"
  log "curl - Used to download RHCOS and OC versions"
  log "genisoimage - Used to create the ISO image"
  log ""
  log "Please install the required packages by running: yum list installed podman curl wget"
  exit
}

log -n "Checking script pre-requisites ..."
yum -q list installed podman curl wget genisoimage > /dev/null

if [ $? != 0 ]; then
  log "FAIL"
  usage
fi

if [ ! -f /usr/local/bin/oc ]; then
  log "FAIL"
  log "Missing oc binary? "
  usage
fi

log "PASS"
  
OCP_VERSION_LATEST=`curl -s -L http://mirror.openshift.com/pub/openshift-v4/clients/ocp | grep "href=\"4."  | awk '{print $5}' | tail -1 | cut -d ">" -f 2 | cut -d "/" -f 1`



function checkPreReqs()
{
    
    log -n "Checking script pre-requisites ..."
    yum -q list installed podman curl wget genisoimage > /dev/null

    if [ $? != 0 ]; then
	log "This script requires the following packages:"
	log "podman - Used to pull supporting images"
	log "wget - Used to retrieve/download RHCOS and OC distributions"
	log "curl - Used to download RHCOS and OC versions"
	log "genisoimage - Used to create the ISO image"
	log ""
	log "Please install the required packages by running: yum list installed podman curl wget genisoimage"
	exit
    fi
    log "PASS"
}

function checkForPullSecretFile()
{
    log "In order for us to retrieve the required components "
    log "for OCP4 (default $OCP_VERSION_LATEST) we will need "
    log "access to the Pull Secret authentication file. "
    log " You can download a pull secrets file from https://cloud.redhat.com/openshift/install. "
    log "NOTE: You MUST download the pull secrets file before proceeding."

    # CHECK=`grep "quay.io" /run/user/$SUDO_UID/containers/auth.json`
    # if [ -z "$CHECK" ]; then
    # 	log "You must authenticate with quay.io"
    # 	while [ "$ans." == "." ]; do
    # 	    log "Would you like to authenticate now?"
    # 	    read ans
    # 	    if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
    # 		podman login quay.io
    # 		if [ $? == 0 ]; then
    # 		    log "Continuing ..."
    # 		    env 
    # 	        fi
    # 	    elif [ "$ans" == "n" ] || [ "$ans" == "N" ]; then
    # 		log  "You must authenticate with quay.io before continuing."
    # 		log  "Exiting"
    # 		exit
    # 	    else
    # 		unset ans
    # 	    fi
    # 	done
    # fi
	
    while [ "$PULL_SECRETS_FILE." == "." ]; do
	log -n "Please enter the Pull Secrets file [ default ./pull-secret.txt]: "
	read pullsecretfile
	
	if [ ".$pullsecretfile" == "." ]; then
	    log "Using default value: [ ./pull-secret.txt]: "
	    PULL_SECRETS_FILE="$pullsecretfile"
	    if [ -f $pullsecretfile ]; then
		log -n "Verifying [ $pullsecretfile ]: "
		PULL_SECRETS_FILE="./pull-secret.txt"
		grep -q "cloud.openshift.com" $PULL_SECRETS_FILE
		
		if [ $? == 0 ]; then
		    log " PASS "
		else
		    log "FAILED"
		    log "File does not contain the cloud.openshift.com authentication."
		    log "Please try again."
		    log "Remember that you can download the pull secret file from https://cloud.redhat.com/openshift/install "
		    exit
		fi
	    else
		log "File does not exist."
		log "Have you logged on to cloud.redhat.com to download the pull secret?"
		log "Please try again after you download the pull secret from https://cloud.redhat.com/openshift/install. "
		PULL_SECRETS_FILE=""
		exit
	    fi
	else
	    if [ -f $pullsecretfile ]; then
		PULL_SECRETS_FILE=$pullsecretfile
	    else
		log "File does not exist."
		log "Have you logged on to cloud.redhat.com to download the pull secret?"
		log "Please try again after you download the pull secret from https://cloud.redhat.com/openshift/install. "
		PULL_SECRETS_FILE=""
		exit
	    fi
	fi
    done 
}

function askForOCP4Version()
{
    
    log -n "Please enter the version you would like to retrieve for OCP4 (default $OCP_VERSION_LATEST): "
    read ocpver
    if [ ".$ocpver" == "." ]; then
	OCP_VERSION=$OCP_VERSION_LATEST
    else
	OCP_VERSION=$ocpver
    fi
    
    log -n "Please enter the destination directory for the contents [default is `pwd`/ocp-images]: "
    read targetdir
    
    if [ ".$targetdir" == "." ]; then
	CONTENT_TARGET_DIR="`pwd`/ocp-images"
    else
	CONTENT_TARGET_DIR=$targetdir
    fi
    
    if [ ! -d $CONTENT_TARGET_DIR ]; then
	log "Creating target directory [$CONTENT_TARGET_DIR] "
	mkdir -p $CONTENT_TARGET_DIR
    fi
    
    AVAILABLE_SPACE=`df -Ph $CONTENT_TARGET_DIR | grep -v Filesystem | awk '{print $4}'`
    log "You destination directory has [$AVAILABLE_SPACE] for the contents.  You will need around 7-10G depending on the OCP4 required images."
    log "Hope it's enough!"
}

function askForOCP4TargetPlatform()
{       
    while [ "$CORE_OS_TARGET." == "." ] 
    do
	log "Current supported Cloud/On-Prem platforms are: openstack|rhv|baremetal|aws|azure|gcp|vmware"
	log "This portion of the script will download RH CoreOS image for the selected target "
	log -n "Please enter the target RH CoreOS platform for your OCP4 deployment <openstack|rhv|baremetal|aws|azure|gcp|vmware>: "
	read coreostarget
	
	case $coreostarget in
	    
	    openstack)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=$coreostarget
		;;
	    
	    rhv)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=qemu
		;;
	    
	    aws)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=$coreostarget
		;;
	    
	    azure)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=$coreostarget
		;;
	    
	    baremetal)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=metal
		;;
	    vmware)
		log "Selected $coreostarget CoreOS target"
		CORE_OS_TARGET=$coreostarget
		;;
	    
	    *)
		log "Unknown target platform [$coreostarget]. Please try again."
		log "Current supported Cloud/On-Prem platforms are: openstack|rhv|baremetal|aws|azure|gcp|vmware"
		CORE_OS_TARGET=""
		;;
	esac
	
    done
}

function gatherOCP4Components()
{
    log "Creating Installer Files"
    mkdir -p $CONTENT_TARGET_DIR/installer/images
    mkdir -p $CONTENT_TARGET_DIR/templates
    
    log "Downloading OC Image"
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-client-linux.tar.gz -r -l1 -nd -e robots=off  -P $CONTENT_TARGET_DIR/installer
    
    # Download latest base RHCOS image to be uploaded to your cloud IaaS tenant
    # Getting RH CoreOS file name for the target
    CORE_OS_TARGET_FILE=`curl -L http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest | grep "rhcos-$CORE_OS_TARGET" | awk '{print $6}' | cut -d ">" -f 1 | cut -d "=" -f 2 | sed "s/\"//g"`
    
    log "Downloading RHCOS Image"
    wget http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/$CORE_OS_TARGET_FILE -r -l1 -nd -e robots=off  -P $CONTENT_TARGET_DIR/installer
    #log "Extracting RHCOS Image"
    #gunzip $CONTENT_TARGET_DIR/installer/rhcos*
    
    # Mirror official release images to local images dir
    log "Downloading Openshift Images"
    /usr/local/bin/oc adm -a $PULL_SECRETS_FILE release mirror --from=quay.io/openshift-release-dev/ocp-release:$OCP_VERSION-x86_64 --to="file://openshift/release" --to-dir="$CONTENT_TARGET_DIR/installer/images"
    
    sleep 5 # Weird network timeout race conditions if you don't set this
    # Extract the appropriate pinned installer executable from the upstream image mirror
    log "Downloading Openshift Installer Executable"
    /usr/local/bin/oc adm -a $PULL_SECRETS_FILE release extract --command=openshift-install --from=quay.io/openshift-release-dev/ocp-release:$OCP_VERSION-x86_64 --to="$CONTENT_TARGET_DIR/installer/"
    
    log "Pulling registry image"
    podman pull docker.io/library/registry:2
    log "Pulling nginx image"
    podman pull nginx
    
    # Save the nginx container image to local medium
    log "Saving nginx image"
    podman save --quiet -o $CONTENT_TARGET_DIR/installer/nginx.tar $(podman images -q nginx:latest)
    
    # Save docker registry container image to local medium
    log "Saving registry image"
    podman save --quiet -o $CONTENT_TARGET_DIR/installer/registry.tar $(podman images -q registry:2)
    
    cp -r $CONTENT_TARGET_DIR/templates $CONTENT_TARGET_DIR/installer/
    #cp *.sh $CONTENT_TARGET_DIR/installer
}

function generateOCP4AirGapISOFile()
{
    log "Constructing ISO Artifacts"
    OCP_VERSION=`echo ${OCP_VERSION} | sed "s/\./-/g"`
    genisoimage -J -joliet-long -quiet -r -o $CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso $CONTENT_TARGET_DIR/installer 

    ##### LRC
    mysize=$(find "$CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso" -printf "%s")
    printf "File %s size = %d\n" $fileName $mysize
    echo "${fileName} size is ${mysize} bytes."

    # Check if file is greater than 4G
    if [ $mysize -gt 4294967296 ]; then
	log "The ISO Artifacts file is greater than 4G"
	while [ "$answer." == "." ]; do
	    log -n "Would you like me to split it? [Y/n] "
	    read answer

	    if [ "$answer." == "." ]; then
		answer="y"
	    fi
	    LETTER=$(echo $answer | awk '{print tolower($0)}')
	    case $LETTER in

		y)
		    log -n "Splitting file [$CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso] into 4G chunks..."
		    split -b 4000M --numeric-suffixes=1 --additional-suffix=.iso $CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso $CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}-disk
		    log "DONE."
		    log "Removing original file [$CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso]"
		    rm $CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso
		    ;;
		n)
		    log "Please transfer file [$CONTENT_TARGET_DIR/openshift-offline-components-${OCP_VERSION}.iso] to your "Air Gapped" network"
		    ;;
		
		*)
		    log "Unknown answer. Please try again."
		    answer=""
		    ;;
	    esac
	done
    fi 
}

function cleanUp()
{
    
    #split -b 4000M --numeric-suffixes=1 --additional-suffix=.iso $CONTENT_TARGET_DIR/openshift-offline-installer.iso $CONTENT_TARGET_DIR/openshift-installer-disk
    #rm $CONTENT_TARGET_DIR/openshift-offline-installer.iso
    log -n "Cleaning up ..."
    rm -rf $CONTENT_TARGET_DIR/installer
    rm -rf $CONTENT_TARGET_DIR/containers
    rm -rf $CONTENT_TARGET_DIR/templates
    log "COMPLETE."
}

#OCP_VERSION_LATEST=`curl -s -L http://mirror.openshift.com/pub/openshift-v4/clients/ocp | grep "href=\"4."  | awk '{print $5}' | tail -1 | cut -d ">" -f 2 | cut -d "/" -f 1`

function runGenerate()
{
    log  "This script will create an ISO file with the contents needed to deploy OCP4 in an"
    log  "'Air Gapped' environment."

    # First let's check if we meet the pre requirements
    checkPreReqs
    
    # Second check to see if we have a pull secrets file

    checkForPullSecretFile

    # Third let's ask for the version of OCP they want to images for

    askForOCP4Version
    
    # fourth let's ask the for the target platform
    askForOCP4TargetPlatform

    # Fifth let's start gathering the components
    gatherOCP4Components

    # Last but not least let's construct the supporting ISO files
    generateOCP4AirGapISOFile

    # clean up from our generation tasks
    cleanUp
}

# Start of our script
runGenerate
