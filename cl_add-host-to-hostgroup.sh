#!/bin/bash

# Download the latest version of the installation package

nrds_client_url=https://github.com/alces-software/nagios/archive/master.tar.gz

# Extract files from compressed tarball
#!/bin/bash

if [ -z ${1} ] || [ -z ${2} ]; then
	echo "Usage: ${0} <host> <interval>"
	echo " e.g.: ${0} node902.pri.csf3 3"
	exit 1
fi

host_name=$1
interval=$2

# installation should always be /usr/local/nrdp/clients/nrds/nrdp.cfg

# download the latest package                                                                                                                                                           
nrds_client_url=https://github.com/alces-software/nagios/archive/master.tar.gz                                                                                                          
nagios_package=master.tar.gz                                                                                                                                                            
nagios_dir=nagios-master

wget ${nrds_client_url}
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

cd ${nagios_dir}
rc=$?
if [ ${rc} -ne 0 ]; then
	echo "Error! Could not change directory to ${nagios_dir}"
	exit ${rc}
fi

echo "Installing nrds client..."

source ./installnrds.sh ${host_name} ${interval}

echo "nrds client installed."

echo "Installing nagios plugins..."

source ./installchecks.sh

echo "Nagios plugins installed."

exit 0
