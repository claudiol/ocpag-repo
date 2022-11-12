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

tar -cvf ocp-binaries.tar -C bin/ .
mv ocp-binaries.tar bin_stage/
cp scripts/setup-ocp-bin.sh bin_stage/
makeself --sha256 ./bin_stage  ocp-binaries-installer.run "OpenShift Binary Installer" ./setup-ocp-bin.sh
