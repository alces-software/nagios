#!/bin/bash

thisbranch=`git status | head -1 | grep -o '[[:alnum:]]*$'`

#remove the asterisk from the variable before echoing output.

echo "Updating token on: ${thisbranch}"

client_config_dir="nrds/client-configs"

for config_profile in `ls -1 ${client_config_dir}`; do
	sed -e 's/^//' ${client_config_dir}/${config_profile}/nrds.cfg
done

exit 0
