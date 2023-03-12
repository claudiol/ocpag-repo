#!/bin/sh

ansible-playbook generate.yml -e"@my_variables.yml"
ansible-playbook generate-rh-operators.yml -e"@my_operators.yml"
ansible-playbook generate-community-operators.yml -e"@my_operators.yml"
ansible-playbook generate-bundle.yml -e"@my_operators.yml"
