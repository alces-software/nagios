#!/bin/bash

# Uninstall checks

config_file="nrds/nrds.cfg"
echo ${config_file}

if [ ! -f ${config_file} ];
then
    echo "Error! Can not find config file!"
    exit 1
else
    echo "Success! Found config file: ${config_file}"
fi

plugindirparent=`grep "^PLUGIN_DIR" ${config_file} |\
            sed -e 's/PLUGIN_DIR=//' |\
            sed -e 's/libexec//' |\
            sed -e 's/\"//g'`


if [ -d ${plugindirparent} ];
then
    rm -ri ${plugindirparent}
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        echo "Error! Failed to remove plugin directory. Aborting..."
        exit ${rc}
    else
        echo "Success! Plugin directory removed."
    fi
else
    echo "Error! Plugin directory does not exist!"
fi
