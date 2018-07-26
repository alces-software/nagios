#!/bin/bash

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

short_hostname=`echo ${HOSTNAME} | grep -o "^[A-Za-z0-9]*"`

#Nodes are an exception for this sort of thing. But an easy one at that.

if [ `echo "${short_hostname}" | egrep -ci "node\|hnode"` -eq "1" ]; then
        short_hostname="node"
fi

# Here, the install script determines which config to install based on the short hostname of the machine
# An element of the profiles array has an index which corresponds to the machine(s) in 'machines' array with regards to Nagios configuration requirements.

declare -a nagios_profiles
declare -a cluster_machines
alces_nr_profiles=10

nagios_profiles=(
    'backup'
    'basic'
    'controller'
    'login'
    'masters'
    'mds'
    'nfs'
    'nodes'
    'nodes-with-raid'
    'oss'
    'slurmaster'
    )

cluster_machines=(
    'backup01'  
    'admin01,admin02,infra01,infra03'
    'controller'
    'login1,login2,vlogin01,hservice2'
    'master1,master2,hmaster1,hmaster2,hhablock1-1,hhablock1-2,hhablock2-1,hhablock2-2,hmeta1,hmeta2'
    'mds1'
    'nfs1,nfs2'
    'node,gpu01,phi01,phi02,phi03,phi04,hnode132'
    'himem01,himem02,viz01,viz02'
    'oss1,oss2'
    'infra02'
    )

profile_counter=0
while [ ${profile_counter} -le "${alces_nr_profiles}" ]; do
    if [ `echo "${cluster_machines[profile_counter]}" | egrep -ci "${short_hostname}"` -eq "1" ]; then
        nagios_profile="${nagios_profiles[profile_counter]}"
        break
    else
        ((profile_counter++))
    fi
done

# Check for config file

config_file="nagios/nrds/client-configs/${nagios_profile}/nrds.cfg"

if [ ! -f ${config_file} ];
then
    printf "Error: Config file: ${config_file} not found!\n"
    exit
else
    printf "Success!: Config file ${config_file} found\n"
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

installdir=`grep "^SEND_NRDP" ${config_file} | sed -e 's/SEND_NRDP=//' | sed -e 's/\"//g' | sed -e 's/\/send_nrdp\.sh//'`

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
nrds_installer_dir="nagios"

cp ${nrds_installer_dir}/send_nrdp.sh ${installdir}
rc=$?
if [ ${rc} -ne 0 ];
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
cp ${nrds_installer_dir}/nrds/*.pl ${installdir}/nrds
if [ $? -ne 0 ];
then
    printf "Error! Unable to copy perl scripts!\n"
else
    printf "Success! Perl scripts copied to: ${installdir}/nrds\n"
fi

# Copy the appropriate config in to the install directory.
cp ${nrds_installer_dir}/nrds/client-configs/${nagios_profile}/nrds.cfg ${installdir}/nrds/nrds.cfg
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

printf "*/${interval} * * * * ${installdir}/nrds/nrds.pl -H ${host} > /dev/null 2>&1\n" >> ${tmpfile}

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

