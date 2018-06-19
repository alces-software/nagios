#!/bin/bash

printf "Uninstalling NRDS...\n"

printf "Removing User and Group\n"

user=nagios
group=nagios

getent passwd ${user}
rc=$?

if [ ${rc} -ne 0 ];
then
    printf "User: ${user} not present.\n"
    exit 1
else
    # Clear user's crontab

    crontab -u ${user} -r
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        printf "Error! Problem removing user: ${user}'s cron entry.\n"
        exit ${rc}
    fi

    # Remove user

    userdel ${user}
    if [ $? -ne 0 ];
    then
        printf "Error removing user: ${user}.\n"
    else
        printf "User: ${user} has been removed.\n"
    fi
fi 


getent group ${group}
rc=$?

if [ ${rc} -ne 0 ];
then
    printf "Group: ${group} not present\n"
    exit 1
else
    groupdel ${group}
    if [ ${rc} -ne 0 ];
    then
        printf "Error removing group: ${group}\n"
        exit 1
    else
        printf "Group ${group}, has been removed.\n"
    fi
fi


printf "User and Group no longer present.\n"

# Remember to read all necessary values in from the config file BEFORE removing it!
config_file=nrds.cfg

installdirparent=`grep "^SEND_NRDP" ${config_file} |\
            sed -e 's/SEND_NRDP=//' |\
            sed -e 's/\"//g' |\
            sed -e 's/\/send_nrdp\.sh//' |\
            sed -e 's/\/clients//'`

printf ${installdirparent}

printf "Removing directory: ${installdirparent}\n"

if [ ! -d ${installdirparent} ];
then
    printf "Directory does not exist!\n"
    exit 1
else
    printf "Attempting to remove directory: ${directory}\n"
    #
    # If the config file becomes incorrectly set,
    # absolute damage can potentially bedone to the system, so force interactive mode
    #
    # doublecheck installdirparent variable
    #
    if [ "${installdirparent}" == "" ];
    then
        printf "Error! Installdir Parent is not set correctly.\n"
        exit 1
    fi
    
    rm -ri ${installdirparent}
    if [ $? -ne 0 ];
    then
        printf "Error! Problem removing the directory: ${installdirparent}\n"
        exit 1
    else
        printf "Success! Directory: ${installdirparent} removed.\n"
    fi
fi
