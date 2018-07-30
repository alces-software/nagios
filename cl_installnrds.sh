#!/bin/bash


nagioscheckhost=`hostname -f | sed -e s/.alces.network$//g`
interval=3

echo "Installing Nagios NRDS Client on ${nagioscheckhost}"

# download the latest package
git_nagios_repo_url="https://github.com/alces-software/nagios.git"

# clone the correct branch

# get the name of the cluster
cluster=`hostname -f | cut -d. -f 3`
target_git_branch=${cluster}

echo "Cloning: ${target_git_branch} on: ${git_nagios_repo_url}"

git clone -b ${target_git_branch} ${git_nagios_repo_url}
rc=$?
if [ "${rc}" -ne "0" ]; then
    echo "Error! Unable to clone branch: ${target_git_branch} on: ${git_nagios_repo_url}"
    exit 1
fi

# This is the directory containing installer and NOT the directory that files are installed in.
nrds_installer_dir=nagios
if [ ! -d ${nrds_installer_dir} ]; then
    echo "Error! Something went wrong, nagios directory is not present!"
    exit 1
fi

# Now run the installer
if [ ! -f ${nrds_installer_dir}/installnrds.sh ]; then
    echo "Error! Installation script: installnrds.sh not found!"
    exit 1
fi

bash ${nrds_installer_dir}/installnrds.sh ${nagiocheckhost} ${interval}
rc=$?
if [ "${rc}" -ne "0" ]; then
    echo "Error! Something went wrong with the installation!"
    exit ${rc}
fi

# Run the plugins installer
bash ${nrds_installer_dir}/installchecks.sh
rc=$?
if [ ${rc} -ne 0 ]; then
        echo "Error! Could not install nrds plugins!"
        exit ${rc}
fi

echo "Cleaning up..."

rm -rf nagios
rc=$?
if [  "${rc}" -ne "0"  ]; then
    echo "Error! Unable to remove directory: nagios"
else
    echo "Clean up done"
fi

exit 0
