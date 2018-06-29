Instructions
-------------

Install NRDS Clients on Machines to be Monitored
------------------------------------------------

1. If not already installed, install wget:

    yum -y install wget
    
2. Download NRDP Client Installation files:

    wget https://github.com/alces-software/nagios/archive/master.zip
    
3. Extract the tarball:

    unzip master.zip
    
4. Install the nrds client:

Run the following command:

    cd nagios-master
    
    ./installnrds <hostname> <interval>
    
----------------------------------------------------------------------------------------------------------------------
Example: Install NRDS clients onto the LAPLACE cluster CONTROLLER, with checks that will be run at 3 minute intervals:
----------------------------------------------------------------------------------------------------------------------
    ./installnrds controller.pri.laplace 3 
----------------------------------------------------------------------------------------------------------------------
    
5. Install the Client side checks: (this will contain the check_ping command only for the moment).

    ./installchecks.sh
    
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
