#!/bin/bash

printf "Installing NRDS\n"

# This script required root privileges to work correctly.

if [ ${UID} -ne 0 ];
then
    printf "Error! This script must be run as root!\n"
    exit 1
else
   printf "Success! Running as root.\n"
fi

# Check Invocation Parameters 

if [ -z ${1} ] || [ -z ${2} ];
then
    printf "Usage: ${0} <hostname> <interval>\n"
    exit 1
else
    printf "Hostname is: ${1}\n"
    printf "Interval is: ${2}\n"
fi

host=${1}
interval=${2}

# Checking for dependencies:
# Perl, wget, curl

printf "Checking for Perl...\n"
which perl
rc=$?
if [ ${rc} -ne 0 ];
then
    yum -y install perl
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        "Error! Failed to install perl! Aborting...\n"
        exit ${rc}
    else
        "Success! Perl installed.\n"
    fi
fi

printf "Checking for wget...\n"
which wget
rc=$?
if [ ${rc} -ne 0 ];
then
    yum -y install wget
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        printf "Error! Failed to install wget\n"
        exit ${rc}
    else
        printf "Success! wget installed\n"
    fi
fi

printf "Checking for curl...\n"
which curl
rc=$?
if [ ${rc} -ne 0 ];
then
    yum -y install curl
    rc=$?
    if [ ${rc} -ne 0 ];
    then
        printf "Error! Failed to install curl! Aborting!\n"
        exit ${rc}
    fi
    printf "Success! curl installed.\n"
fi

printf "Adding User and Group...\n"

user=nagios
group=nagios

getent passwd ${user}
if [ $? -eq 0 ]
then
    printf "User: ${user} already exists.\n"
else
    printf "Creating new user: ${user}\n"
    useradd ${user}
fi

getent group ${group}
if [ $? -eq 0 ]
then
    printf "Group: ${group} already exists.\n"
else
    printf "Creating new group: ${group}\n"
    groupadd ${group}
fi

# What type of node is this?

host_type=`echo ${HOSTNAME} | grep -o "^[A-Za-z]*"`

# Checking Config File for send_dir, directory that contains the script
# that will be used to send the data to the NRDP server.
# This will be our installation directory for NRDS/NRDP clients

# Check for config file

config_file="nagios-master/nrds/client-configs/${host_type}/nrds.cfg"
printf "${config_file}\n"

if [ ! -f ${config_file} ];
then
    printf "Error: Config file: ${config_file} not found!\n"
    exit
else
    printf "Success!: Config file ${config_file} found\n"
fi

installdir=`grep "^SEND_NRDP" ${config_file} |\
            sed -e 's/SEND_NRDP=//' |\
            sed -e 's/\"//g' |\
            sed -e 's/\/send_nrdp\.sh//'`

printf ${installdir}

mkdir -p ${installdir}

if [ $? -ne 0 ];
then
    printf "Error! Unable to create installation directory: ${installdir}\n"
    exit 1
else
    printf "Success! Installation directory: ${installdir} created\n"
fi

chown -R ${user}:${group} ${installdir}
if [ $? -ne 0 ];
then
    printf "Unable to set ownership on Installation directory: ${installdir}, exiting...\n"
    exit 1
else
    printf "Ownership set on Installation directory: ${installdir}\n"
fi

# Copy files from this directory into the install directory

cp  send_nrdp.sh ${installdir}
if [ $? -ne 0 ];
then
    printf "Error! Unable to copy send_nrds.sh into install directory.\n"
fi

mkdir ${installdir}/nrds 
if [ $? -ne 0 ];
then
    printf "Error! Unable to create nrds directory in ${installdir}!\n"
else
    printf "Success! nrds directory created!\n"
fi

# Copy PERL scripts into ${installdir}/nrds directory
cp nagios-master/nrds/*.pl ${installdir}/nrds
if [ $? -ne 0 ];
then
    printf "Error! Unable to copy perl scripts!\n"
else
    printf "Success! Perl scripts copied to: ${installdir}/nrds\n"
fi

# Copy the appropriate config in to the install directory.
cp nagios-master/nrds/client-configs/${host_type}/nrds.cfg ${installdir}/nrds/nrds.cfg
if [ $? -ne 0 ] ;
then
    printf "Error! Unable to copy the correct config in to: ${installdir}/nrds\n"
else
    printf "Success! nrds.cfg copied to $installdir/nrds"
fi

#
# Install perl script : nrds.pl to crontab for nagios user
#
tmpfile="nagioscron.tmp"

printf "${tmpfile}\n"

printf "For the Host: ${host}, You have chosen an interval of : ${interval} minutes.\n"

# Save the current crontab
crontab -u ${user} -l > ${tmpfile}

if [ ! -f ${tmpfile} ]
then
    printf "Error! Unable to create temporary file: ${tmpfile}\n"
fi

printf "*/${interval} * * * * ${installdir}/nrds/nrds.pl -H ${host}\n" >> ${tmpfile}

crontab ${tmpfile} -u ${user}

if [ $? -ne 0 ];
then
    printf "Error! Could not add job to cron!\n"
else
    printf "Success! Job added to cron!\n"
fi

rm ${tmpfile}
if [ $? -ne 0 ];
then
    printf "Error! Could not remove temporary file ${tmpfile}\n"
fi

