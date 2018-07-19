#!/bin/bash

# Reads a list of nodes from a file and adds each node to a hostgroup.

# This script has to be run on the server.

if [ "${HOSTNAME}" != "flightcenter-nagios2.alces-flight.com" ]; then
	echo "Error! This script must be run on: flightcenter-nagios2.alces-flight.com"
	exit 1
fi

nagioscheckhostfile=$1
cluster=$2

if [ -z ${nagioscheckhostfile} ] || [ -z ${cluster} ]; then
    echo "Error! Usage: ${0} <file containing list of short hostnames> <cluster>"
    exit 1
fi

# Cluster must have already been defined.

object_directory="/usr/local/nagios/etc/objects"

if [ ! -f ${object_directory}/${cluster} ]; then
    echo "Error! Cluster: ${cluster} does not have a directory!"
    exit 1
fi

while read nagioscheckhost; do
    ./sv_add-host-to-hostgroup.sh ${nagioscheckhost}.pri.${cluster}
done < ${nagioscheckhostfile}

echo "Be sure to run: /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg before restarting nagios!"

exit 0
