#!/bin/bash

# Adds a node to the hostgroup.

if [ "${HOSTNAME}" != "flightcenter-nagios2.alces-flight.com" ]; then
        echo "Error! This script must be run on: flightcenter-nagios2.alces-flight.com"
        exit 1
fi

# Ensure parameters are being passed
if [ -z ${1} ] ; then
        echo "Usage: ${0} <hostname>"
        exit 1
fi

# new_host: e.g. xyz.pri.abc
new_host=${1}

# Get the name of the clsuter (last alphanumeric string between the end of the line ('\n' and the first non-alphanumeric character, namely .)
hostgroup=`echo ${new_host} | grep -o "[[:alnum:]]*$"`

# Use the name of the host to determine the monitoring profile 
host_type=`echo ${new_host} | grep -o "^[A-Za-z0-9]*"`

# The way in which monitoring profiles are determined requires the digits after "node" to be trunctated 
if [ `echo ${host_type} | grep -ci "^node\|gpu\|phi"` -ne 0 ]; then
    host_type="node"
elif [ `echo ${host_type} | grep -ci "^himem\|viz"` -ne 0 ]; then
    host_type="nodes-with-raid"
fi

objects_directory="/usr/local/nagios/etc/objects"

# This is where parent directory of the generic-cluster. This is nothing more than a folder that contains template object definitions.
# These are different from the template definitons in Nagios.
#
# The generic-cluster contains skeleton object definitions for all types of machines and hostgroups.
# When individual hosts are added to the cluster using this script, the corresponding template in the generic-cluster/hosts directory is
# copied to the new directory.
template_dir=${objects_directory}/generic-cluster
template_host=${template_dir}/hosts/${host_type}.pri.CLUSTER.cfg

# Make sure the hostgroup has its own directory
if [ ! -d ${objects_directory}/${hostgroup} ]; then
        echo "Error! Hostgroup: ${hostgroup} must have already been created!"
        exit ${rc}
fi

# Make sure the host doesn't already exist
if [ -f ${objects_directory}/${hostgroup}/hosts/${new_host}.cfg ]; then
        echo "Error! Host: ${new_host} already has a file!"
        exit 1
fi

# Make sure the host is not already present as a member of the given host group
# This situation arises if an incomplete setup has occured.
grep -i "${new_host}" ${objects_directory}/${hostgroup}/${hostgroup}-hostgroup.cfg > /dev/null 2>&1
rc=$?
if [ ${rc} -eq 0 ]; then
        echo "This host is already in the hostgroup: ${hostgroup}"
        exit 1
fi

# Copy the template file, check it still exists!
if [ ! -f ${template_host} ]; then
        echo "Error! Template file: ${template_host} missing!"
        exit 1
fi

echo "Copying: ${template_host} to ${objects_directory}/${hostgroup}/hosts/${new_host}.cfg........"
cp ${template_host} ${objects_directory}/${hostgroup}/hosts/${new_host}.cfg
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Unable to copy template host and create a new file!"
        exit ${rc}
fi

# Modify the file
new_host_file=${objects_directory}/${hostgroup}/hosts/${new_host}.cfg
sed -ie "s/\(host_name[[:space:]]*\).*/\1${new_host}/g" ${new_host_file} > /dev/null 2>&1
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Unable to update the host_name directive with ${new_host}!"
        exit 1
fi
# Remove backup files...the original file's extension (cfg) has an 'e' appended to it.
if [ -f ${new_host_file}e ]; then
    echo "Removing Backup Files"
    rm -f ${new_host_file}e
fi

new_hostgroup_file=${objects_directory}/${hostgroup}/${hostgroup}-hostgroup.cfg
sed -ie "s/\(members.*\)/\1, ${new_host}/g" ${new_hostgroup_file} > /dev/null 2>&1
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Unable to add ${new_host} to the  members directive of the hostgroup object for the ${hostgroup} cluster"
        exit 1
fi

# Remove backup files...the original file's extension (cfg) has an 'e' appended to it.
if [ -f ${new_hostgroup_file}e ]; then
    echo "Removing Backup Files"
    rm -f ${new_hostgroup_file}e
fi

echo "Be sure to run: /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg before restarting nagios!"

exit 0
