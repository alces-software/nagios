INSTRUCTIONS
############

1. Run ./installnrds.sh <hostname of machine to be monitored> <monitoring interval> 
          e.g. # ./installnrds.sh passive_host_test2 3
2. Run ./installchecks.sh
3. On the server,
          e.g. #  cd /usr/local/nagios/etc/objects/passive_check_hosts
4. Copy the passive_host_test.cfg 
	e.g. # cp passive_host_test.cfg passive_host_test2.cfg
5. Rename the references to 'passive_host_test'  in this file to 'passive_host_test2'
	e.g. # sed -i 's/passive_host_test/passive_host_test2/g' passive_host_test2.cfg
6. Syntax check on nagios config file:
	e.g. # /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
7. restart nagios:
	e.g. # systemctl restart nagios
8. Check the Web UI to confirm the host has been added.

Contents
########

installnrds.sh 
##############
1) Adds the nagios user and nagios group.
2) Creates the directory structure.
3) Sets permissions/ownership.
4) Adds perl script to crontab.

nrds.cfg
########
contains parameters that vary dependent on where the scripts are deployed or that may be useful in case some change is required.

send_nrdp.sh
############
This script is the part of the nrdp client on the remove machine that is used to send the data to the NRDP server.
This is invoked by the perl script when it is executed via cron.

nrds
####
This directory contains perl scripts:
nrds.pl - Master script that obtains config information and then invokes send_nrdp.sh, run by cron.
nrds_updater.pl - obtains plugins and config updates from the NRDP server (not yet in use by us)
nrds_common.pl - perl code that is used by both nrds.pl and nrds_updater.pl
