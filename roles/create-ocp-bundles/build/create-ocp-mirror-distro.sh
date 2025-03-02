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

let COUNT=0
mkdir -p $TEMPDIR/image_stage
cp $ROLEDIR/build/scripts/extract-image-set.sh $TEMPDIR/image_stage/
for i in `ls $BUNDLEDIR/openshift-release-dev/*.tar`
do 
  BASE=$(basename $i)
  cp $i $TEMPDIR/image_stage/$BASE
  makeself --sha256 $TEMPDIR/image_stage  $TEMPDIR/ocp-$OCPVERSION-image-set-installer-$COUNT.run "OpenShift Image Set Installer" ./extract-image-set.sh
  rm -f $TEMPDIR/image_stage/$BASE
  let COUNT++
done
rm -rf $TEMPDIR/image_stage
