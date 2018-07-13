#!/bin/bash

#Adds a node to the hostgroup.

# Ensure parameters are being passed
if [ -z ${1} ] ; then
        echo "Usage: ${0} <hostname>
        echo " e.g.: ${0} node900.pri.csf3
        exit 1
fi

new_host=${1}
hostgroup=`echo ${new_host} | grep -o "[[:alnum:]]*$"`
host_type=`echo ${new_host} | grep -o "^[A-Za-z0-9]*"`
basedir="/usr/local/nagios/etc/objects"
template_dir=${basedir}/generic-cluster
template_host=${template_dir}/hosts/${host_type}.pri.CLUSTER.cfg

# Make sure the hostgroup has its own directory
if [ ! -d ${basedir}/${hostgroup} ]; then
        echo "Error! Hostgroup: ${hostgroup} must have already been created!"
        exit ${rc}
fi

# Make sure the host doesn't already exist
if [ -f ${basedir}/${hostgroup}/hosts/${new_host}.cfg ]; then
        echo "Error! Host: ${new_host} already has a file!"
        exit 1
fi

# Make sure the host is not already present as a member of the given host group
# This situation arises if an incomplete setup has occured.
grep -i "${new_host}" ${basedir}/${hostgroup}/${hostgroup}-hostgroup.cfg > /dev/null 2>&1
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

echo "Copying: ${template_host} to ${basedir}/${hostgroup}/hosts/${new_host}.cfg........"
cp ${template_host} ${basedir}/${hostgroup}/hosts/${new_host}.cfg
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Unable to copy template host and create a new file!"
        exit ${rc}
fi

# Modify the file
new_host_file=${basedir}/${hostgroup}/hosts/${new_host}.cfg
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

new_hostgroup_file=${basedir}/${hostgroup}/${hostgroup}-hostgroup.cfg
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


echo "Done..."
echo "Be sure to run: /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg before restarting nagios!"

exit 0
