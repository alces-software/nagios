#!/bin/bash

new_token=$1

if [ -z ${1} ]; then
    echo "Error: Usage: ${0} <new token>"
    exit 1
fi

echo "Updating tokens for nrdp clients on `hostname -f`"

sed -ie 's#\(TOKEN="\)[[:alnum:]]*\("\)#\1'"${new_token}"'\2#g' /usr/local/nrdp/clients/nrds/nrds.cfg
rc=$?
if [ "${rc}" -ne "0" ]; then
    echo "Error! Token not updated!"
    exit "${rc}"
fi

exit 0
