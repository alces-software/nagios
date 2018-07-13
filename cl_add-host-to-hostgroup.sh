#!/bin/bash

if [ -z ${1} ] || [ -z ${2} ]; then
    echo "Usage: ${0} <host> <interval> (interval in minutes)"
    echo " e.g.: ${0} node01.pri.laplace 3"
    exit 1
fi

client_host=${1}
interval=${2}

# download the latest package
gitrepo=https://github.com/alces-software/nagios/archive/master.tar.gz
nagios_package=master.tar.gz
nagios_dir=nagios-master

wget ${gitrepo}
rc=$?
if [ ${rc} -ne 0 ] ; then
        echo "Error! Unable to download latest package! wget rc: ${rc}"
        exit ${rc}
fi

tar xvzf ${nagios_package}
rc=$?
if [ ${rc} -ne 0 ] ; then
        echo "Error! Could not extract package: ${nagios_package}! tar rc: ${rc}"
        exit ${rc}
fi

# Run the nrds installer
source ${nagios_dir}/installnrds.sh ${client_host} ${interval}
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Problem with nrds installation on ${HOSTNAME}. Error encounting while running installnrds.sh"
        exit ${rc}
fi

# Run the plugins installer
source ${nagios_dir}/installchecks.sh
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Could not install nrds plugins!"
        exit ${rc}
fi

exit 0
