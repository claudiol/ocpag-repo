#!/bin/sh
#

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

export TMP=/home/claudiol/temp
export TMPDIR=/home/claudiol/temp
export TEMP=/home/claudiol/temp

let COUNT=0
mkdir -p image_stage
cp scripts/extract-image-set.sh image_stage/
for i in `ls openshift-release-dev/*.tar`
do 
  BASE=$(basename $i)
  cp $i image_stage/$BASE
  makeself --sha256 ./image_stage  ocp-image-set-installer-$COUNT.run "OpenShift Image Set Installer" ./extract-image-set.sh
  rm -f image_stage/$BASE
  let COUNT++
done
