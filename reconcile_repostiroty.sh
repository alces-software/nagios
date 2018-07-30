#!/bin/bash

# Use this script to ensure that each branch has the same copy of the latest file.

# Some files are generic and applicable to all clusters/branches of this repository, however maintaining these can be error prone and cumbersome.

latest_file=$1

if [ -z "${1}" ]; then
	echo "Error! Usage: ${0} <file_to reconcile accross repos branches>"
	exit 1
fi

if [ ! -f ${latest_file} ]; then
	echo "Error! File ${latest_file} does not exist or is outside `pwd`"
	exit 1
fi

# Make a copy of the latest file outside this repo
cp -p "${latest_file}" /tmp/nagios/"${latest_file}"

# Globbing needs to be disabled, to handle the * asterisk character as input and format the inputput appropriately.
set -f

for branch in `git branch`;  do
	if [ "${branch}" == "*" ]; then
		continue;
	fi
	echo "Updating ${branch} with ${latest_file}"

	# checkout to this branch
	git checkout "${branch}"

	# Now overwrite our outdated file with the latest.
	cp -p /tmp/nagios/"${latest_file}" "${latest_file}"

	git add "${latest_file}"

	git commit -m "Updated ${branch} with ${latest_file}"

	git push origin "${branch}"
done


# Restore globbing.
set +f

exit 0
