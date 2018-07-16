Install NRDS Clients on Machines to be Monitored
------------------------------------------------

Downloads and runs shell script from the Nagios repository, that adds the client side monitoring checks necessary for passive Nagios checks.

1. Log in to the controller.

2. Download NRDP Client Installation files:

If monitoring a cluster CONTROLLER, run the following command:

    curl https://raw.githubusercontent.com/alces-software/nagios/master/cl_add-host-to-hostgroup.sh | /bin/bash

If monitoring a machine other than a controller, run the following command:

    pdsh -w <hostname(s)> 'curl https://raw.githubusercontent.com/alces-software/nagios/master/cl_add-host-to-hostgroup.sh | /bin/bash'
 
 Where hostnames refers to the set of machines to be monitored, using the standard syntax used for pdsh.
 
----------------------------------------------------------------------------------------------------------------------
Example: Install NRDS and Nagios Checks on Compute nodes 922
----------------------------------------------------------------------------------------------------------------------
    pdsh -w node[922-926] 'curl https://raw.githubusercontent.com/alces-software/nagios/master/cl_add-host-to-hostgroup.sh | /bin/bash'
----------------------------------------------------------------------------------------------------------------------
 
    
Installation of the NRDP Client on the remote machine is now complete.


Contents
--------

installnrds.sh 
--------------
1) Adds the nagios user and nagios group.
2) Creates the directory structure.
3) Sets permissions/ownership on the directories and files.
4) Adds perl script to crontab.

installchecks.sh
----------------
Creates the directory structure for the checks and copies the default checks from their install package to their new directory.

uninstallnrds.sh
----------------
Undoes everything done by installnrds.sh - restores the state of the system to as it was prior to running installnrds.sh
(very helpful for testing enhancements to installnrds.sh)

uninstallchecks.sh
------------------
Undoes everything doen by installchecks.sh - restores the state of the system to as it was prior to running installchecks.sh
(very helpful for testing enhancements to installchecks.sh)

nrds.cfg
--------
Used by nrdp.sh and nrds.pl and installnrds.sh.
These scripts carry out their operations on parameterised data that is supplied by this file. For example, nrds.pl uses nrds.cfg to
determine which checks to run. 

send_nrdp.sh
------------
Used to submit passive check data to the NRDS server.

nrds
----
nrds.pl - Master script that obtains config information and then invokes send_nrdp.sh, run by cron. Run every 3 minutes by default
nrds_updater.pl - obtains plugins and config updates from the NRDP server (not yet in use by us)
nrds_common.pl - perl code that is used by both nrds.pl and nrds_updater.pl
