#!/bin/bash

cleanup () {
    rm ${nagios_package}
    rm -rf ${nagios_dir}
}

# installation should always be /usr/local/nrdp/clients/nrds/nrdp.cfg

# download the latest package
gitrepo=https://github.com/alces-software/nagios/archive/master.tar.gz
nagios_package=master.tar.gz

nagios_dir=nagios-barkla

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

short_hostname=`echo ${HOSTNAME} | grep -o "^[A-Za-z0-9]*"`

# Here, the install script determines which config to install based on the short hostname of the machine
# An element of the profiles array has an index which corresponds to the machine(s) in 'machines' array with regards to Nagios configuration requirements.

declare -a nagios_profiles
declare -a cluster_machines

nagios_profiles=(
    'backup'
    'basic'
    'controller'
    'login'
    'masters'
    'nodes'
    'slurmaster'
    )

cluster_machines=(
    'master1'  
    'admin01,admin02,infra01'
    'controller'
    'login1'
    'master'
    'node'
    'infra02'
    )

counter=0
while [ ${counter} -le "7" ]; do
    if [ `echo "${short_hostname}" | grep -ci "${cluster_machines[counter]}"` -eq "1" ]; then
        nagios_profile="${nagios_profiles[counter]}"
        break
    else
        ((counter++))
    fi
done

# Compare the latest nrds.cfg with the installed nrds.cfg
installdir=/usr/local/nrdp/clients/nrds

diff -q ${installdir}/nrds.cfg ${nagios_dir}/nrds/client-configs/${nagios_profile}/nrds.cfg
rc=$?
if [ ${rc} -eq 0 ] ; then
	echo "Installed Config is Latest."
	cleanup
else
	echo "Updating..."

	# Replace the installed config with the updated config.

	cp ${nagios_dir}/nrds/client-configs/${nagios_profile}/nrds.cfg ${installdir}/nrds.cfg
	rc=$?
	if [ ${rc} -ne 0 ]; then
	    echo "Error! Unable to Update new config!"
	    exit ${rc}
        fi

        source ./installchecks.sh
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Error! Problem Installing Checks! installchecks.sh rc: ${rc}"
		cleanup
		exit ${rc}
	fi
fi
