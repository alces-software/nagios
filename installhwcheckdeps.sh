#!/bin/bash

# This script will install any necessary dependencies related to hardware checks such as:
# ipmi tool
# megacli

ipmitoolrequired="0"
megaraidrequired="0"
hpssaclirequired="0"

# Flag which checks have been installed.
pluginsdir="/usr/local/nagios/libexec"
if [ -f "${pluginsdir}/check_ECC-IPMI" ] || [-f "${pluginsdir}/check_inlettemp"]; then
    ipmitoolrequired="1"
fi

if [ -f "${pluginsdir}/check_PERC_H7X0" ]; then
    megaraidrequired="1"
fi

if [ -f "${pluginsdir}/check_hpe_SA_RAID"  ]; then
    hpssaclirequired="1"
fi

# sanity check on flags

if [ "${hpssaclirequired}" == "1" ] && [ "${megaraidrequired}" == "1" ]; then
        echo "Error! hpssacli and MegaRAID on the same machine? Fix the checks..."
        exit 1
fi

echo "Flags are sane, proceeding to installation of check dependencies"

# check to see if ipmitool is installer and if it is not, then install it.
# make sure to not install from epel

if [ "${ipmitoolrequired}" == "1" ]; then
    `which ipmitool`
    rc=$?
    if [ "${rc}" -ne "0" ]; then
        echo "Installing ipmitool..."
        yum -y --disablerepo epel install freeipmi
        rc=$?
        if [ "${rc}" -ne "0" ]; then
                yum -y install freeipmi
                rc=$?
                if [ "${rc}" -ne "0"  ]; then
                        echo "Error! Unable to install freeipmi."
                        exit "${rc}"
                fi
        fi
        echo "ipmitool installation complete."
        echo "You must also enter the credentials for the controller to access the nodes."
    fi
    echo "ipmitool already installed, nothing to do..."
fi

if [ "${megaraidrequired}" == "1" ]; then
    if [[ ! -x "/opt/MegaRAID/MegaCli" ]]; then
            echo "Installing MegaCli..."
            yum -y install MegaCli
            rc=$?
            if [ "${rc}" -ne "0" ]; then
                echo "Error! Unable to install MegaCli"
            fi
            echo "MegaCli installation complete."
    fi
    echo "MegaCli already installed, nothing to do..."
fi

if [ "${hpssaclirequired}" == "1" ]; then
        `which hpssacli`
        rc=$?
        if [ "${rc}" -ne "0" ]; then
                echo "Installing hpssacli"
                yum -y install hpssacli
                rc=$?
                if [ "${rc}" -ne "0" ]; then
                        echo "Error! Unable to install hpssacli"
                fi
                echo "hpssacli installation complete."
        fi
fi

exit 0
