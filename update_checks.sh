#!/bin/bash

if [ -z $1 ]; then
    echo "Usage: $0 <check_name>"
    exit 1
fi

check_to_update=$1
check_directory="/usr/local/nagios/libexec"

# It should not matter that this check comes from the master repo
# All branches should have the same content in their nagios-plugins directory.

raw_checks_url="https://raw.githubusercontent.com/alces-software/nagios/master/nagios-plugins"

echo ${check_to_update}
echo "Check directory is: ${check_directory}"

if [ ! -f ${check_directory}/${check_to_update} ]; then
    echo "Error! check: ${check_to_update} does not exist."
    exit 1
fi

echo "Downloading updated check..."

wget "${raw_checks_url}/${check_to_update}"


if [ $? -ne 0 ]; then
    echo "Error! Problem downloading ${check_to_update} from ${raw_checks_url}"
    exit 1
fi

mv ${check_to_update} ${check_directory}
if [ $? -ne 0 ]; then
    echo "Error! Unable to mv ${check_to_update} to ${check_directory}"
    exit 1
fi

chmod 550 ${check_directory}/${check_to_update}
if [ $? -ne 0 ]; then
    echo "Error setting permissions on ${check_directory}/${check_to_update}"
    exit 1
fi

chown nagios:nagios ${check_directory}/${check_to_update}
if [ $? -ne 0 ]; then
    echo "Error setting ownership to nagios:nagios for ${check_directory}/${check_to_update}"
    exit 1
fi

echo "Done"

exit 0

