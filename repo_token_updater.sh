#!/bin/bash

new_token=$1

if [ -z "${1}" ]; then
        echo "Error! Usage: ${0} <new token>"
        exit 1
fi

this_branch=`git status | head -1 | grep -o '[[:alnum:]]*$'`

echo "Updating token on: ${this_branch}"

client_config_dir="nrds/client-configs"

for config_profile in `ls -1 ${client_config_dir}`; do
    sed -ie 's#\(TOKEN="\)[[:alnum:]]*\("\)#\1'"${new_token}"'\2#g' ${client_config_dir}/${config_profile}/nrds.cfg
done

exit 0
