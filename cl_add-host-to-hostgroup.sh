#!/bin/bash

nagioscheckhost=`hostname -f | sed -e s/.alces.network$//g`
interval=3

# download the latest package
gitrepo=https://github.com/alces-software/nagios/archive/barkla.tar.gz
nagios_package=barkla.tar.gz
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
	echo "Removing ${nagios_package}...."
	rm -f ${nagios_package}
        exit ${rc}
fi

# Run the nrds installer
source ${nagios_dir}/installnrds.sh ${nagioscheckhost} ${interval}
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Problem with nrds installation on ${nagiocheckhost}. Error encounting while running installnrds.sh"
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
