#!/bin/bash

file_to_scp=$1
target_machines=$2

if [ -z ${1} ] || [ -z ${2} ]; then
    echo "Error! Usage: ${0} <file to scp> <Target Machine(s)>"
    echo "        e.g.: ${0} somefile.txt compute"
    exit 1
fi

for machine in `nodeattr -n ${target_machines}`; do
    scp ${file_to_scp} ${machine}:/root
    rc=$?
    if [ "${rc}" -ne "0" ]; then
        echo "Error! Could not scp!"
        exit 1
    fi
done

exit 0
