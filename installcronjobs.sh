#!/bin/bash

# There are only two cronjobs that are dependencies.
# alces-ipmi-check

# If the /usr/local/nagios/libexec contains check_ECC_IPMI, then install the necessary cron dependency.

checks_directory=/usr/local/nagios/libexec


if [ -f ${checks_directory}/check_ECC-IPMI ]; then
	cp cronjobs/alces-ipmi-check /etc/cron.hourly
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Failed to copy: alces-ipmi-check to /etc/cron.hourly"
	fi

	echo "check_ECC-IPMI dependencies have been successfully copied"
fi

if [ -f ${checks_directory}/check_dirvish ]; then
	cp cronjobs/check_dirvish /var/spool/nagios
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Failed to copy: cronjobs/check_dirvish to /var/spool/nagios"
	fi

        cp cronjobs/dirvish-cronjob /etc/dirvish
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Failed to copy: cronjobs/dirvish-cronjob to /etc/dirvish"
	fi
	
	cp cronjobs/dirvish /etc/cron.d
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Failed to copy: cronjobs/dirvish to /etc/cron.d"
	fi

	echo "check_dirvish dependencies have been successfully copied."
fi

exit 0
