#!/bin/sh
#

BUNDLEDIR=""
TEMPDIR="/tmp"

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
	if [ -z "$2" ]; then
		echo -e "\033[0K\r\033[1;36m$1\033[0m"
	else
		echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
	fi
}

while getopts "d:t:r:" opt
do
    case $opt in
	(d) BUNDLEDIR=$OPTARG
	    ;;
	(r) ROLEDIR=$OPTARG
	    ;;
	(t) TEMPDIR=$OPTARG
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" && exit 1
	    ;;
    esac
done

if [ -z $BUNDLEDIR ]; then
    log "Please pass in the top level dir for the bundle"
    exit 1
elif [ ! -d $BUNDLEDIR ]; then
    log "The [$BUNDLEDIR] directory does not exist"
    log "Please pass in the top level dir for the bundle"
    exit 2
fi
      
if [ -f $BUNDLEDIR/bin/bundle-manifest.yaml ]; then
  OCPVERSION=$(cat $BUNDLEDIR/bin/bundle-manifest.yaml | grep ocp_version | sed "s|ocp_version: ||g")
else
  OCPVERSION=4
fi

mkdir -p $TEMPDIR/containers_stage
tar -cvf $TEMPDIR/ocp-containers.tar -C $BUNDLEDIR/containers/ .
mv $TEMPDIR/ocp-containers.tar $TEMPDIR/containers_stage/
cp $ROLEDIR/build/scripts/extract-containers-set.sh $TEMPDIR/containers_stage/
makeself --sha256 $TEMPDIR/containers_stage  $TEMPDIR/ocp-containers-installer.run "OpenShift Supporting Services Installer" ./extract-containers-set.sh
rm -rf $TEMPDIR/containers_stage
