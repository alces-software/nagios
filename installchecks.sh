#!/bin/bash

#
# Installs nagios plugins on remote machines
# 

# Create a directory to place the checks in.

user=nagios
group=nagios
config_file="/usr/local/nrdp/clients/nrds/nrds.cfg"

printf ${config_file}

if [ ! -f ${config_file} ];
then
    printf "Error! Can not find config file!\n"
    exit 1
else
    printf "Success! Found config file: ${config_file}\n"
fi

plugindir=`grep "^PLUGIN_DIR" ${config_file} |\
            sed -e 's/PLUGIN_DIR=//' |\
            sed -e 's/\"//g'`

printf "Plugin Directory is: ${plugindir}\n"
printf "Creating Checks directory: ${plugindir}\n"

if [ ! -d ${plugindir} ];
then
    mkdir -p ${plugindir}
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        printf "Error! Unable to mkdir ${plugindir}, aborting...\n"
        exit ${rc}
    else
        printf "Success! Created plugins directory...\n"
    fi
else
    printf "Checks directory already exists...\n"
fi

# If a check is defined twice for a config file, the check will actually get copied twice 
# (this isn't really a problem...)

nrds_installer_dir="nagios"
# Copy checks in to the checks directory
for check in `egrep -o "check[A-Za-z0-9_.-]*" ${config_file}`
do
    echo "Copying ${check} ......................................."
    cp ${nrds_installer_dir}/nagios-plugins/${check} ${plugindir}
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        printf "Error! Unable to copy check: ${check} into the target directory, aborting...\n"
    else
    printf "Success! Checks copied in to plugin directory ${plugindir}...\n"
fi
    
done


# Set ownership
chown -R ${user}:${group} ${plugindir}
rc=$?
if [ ${rc} -ne 0 ];
then
    printf "Error! Unable to set ownership of user: ${user} and group: ${group} on directory: ${plugindir}\n"
    exit 1
else
    printf "Success! directory: ${plugindir} now has an owner of user: ${user} and group: ${group}\n"
fi

# Set permissions on checks - Nagios user needs to read and execute only
chmod 550 ${plugindir}/* 
rc=$?
if [ ${rc} -ne 0 ];
then
    printf "Error ! Unable to set permissions on the check scripts...\n"
    exit ${rc}
else
    printf "Success! Permissions set on the check files...\n"
fi

exit 0
