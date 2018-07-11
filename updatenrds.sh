#!/bin/bash

# installation should always be /usr/local/nrdp/clients/nrds/nrdp.cfg

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

# Compare the latest nrds.cfg with the installed nrds.cfg
installdir=/usr/local/nrdp/clients/nrds
#host_type=echo "${HOSTNAME} | grep
host_type=controller
diff -q ${installdir}/nrds.cfg ${nagios_dir}/nrds/client-configs/${host_type}/nrds.cfg
rc=$?
if [ ${rc} -eq 0 ]; then
	echo "Installed Config is Latest."
	exit 0
else
	echo "Updating..."
        source ./installchecks.sh
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Error! Problem Installing Checks! installchecks.sh rc: ${rc}"
		exit ${rc}
fi
