#!/bin/sh

echo -n "Generating OpenShift images ..."
RC=$(ansible-playbook generate.yml -e"@my_variables.yml" > /tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit
fi
echo " done"
echo -n "Generating Red Hat OpenShift operators ..."
RC=$(ansible-playbook generate-rh-operators.yml -e"@my_variables.yml">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit
fi
echo " done"
echo -n "Generating Community OpenShift operators ..."
RC=$(ansible-playbook generate-community-operators.yml -e"@my_variables.yml">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit
fi
echo " done"
echo -n "Generating OpenShift self-extracting bundles ..."
RC=$(ansible-playbook generate-bundle.yml -e"@my_variables.yml">>/tmp/log.txt 2>&1;echo $?)
if [ $RC -gt 0 ]; then
  echo "Failed"
  exit
fi
echo " done"
