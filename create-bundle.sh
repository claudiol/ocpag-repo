#!/bin/sh

vars_file=$1

if [ -z "$vars_file" ]; then
  echo "Please pass a vars file argument"
  echo ""
  echo "Usage: $0 [vars_file]"
  exit 1
fi

echo -n "Generating OpenShift images ..."
RC=$(ansible-playbook generate.yml -e"@${vars_file}" > /tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit 1
fi
echo " done"
echo -n "Generating Red Hat OpenShift operators ..."
RC=$(ansible-playbook generate-rh-operators.yml -e"@${vars_file}">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit 1
fi
echo " done"
echo -n "Generating Community OpenShift operators ..."
RC=$(ansible-playbook generate-community-operators.yml -e"@${vars_file}">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit 1
fi
echo " done"
echo -n "Generating Certified OpenShift operators ..."
RC=$(ansible-playbook generate-certified-operators.yml -e"@${vars_file}">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit 1
fi
echo " done"
echo -n "Generating OpenShift self-extracting bundles ..."
RC=$(ansible-playbook generate-bundle.yml -e"@${vars_file}">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit 1
fi
echo " done"
