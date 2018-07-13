#!/bin/bash -l

# Plugin to check slurm status

if [ ! -x /usr/bin/sinfo ] ; then
   echo "No sinfo command found - is slurm installed?"
   exit 3
fi

outputfile=/tmp/slurmoutput.$$

# Don't hang-up the plugin if sinfo takes too long to return
/usr/bin/sinfo -Nl > $outputfile 2>&1 &
sleep 2

# Init variables
unexpected=0
totalnodes=0

# Add checks here
unexpected=`grep -ci unexpected $outputfile | awk '{print $1}'`
lines=`wc -l $outputfile | awk '{print $1}'`
totalnodes=`expr $lines - 2`
down=`grep -ci down $outputfile | awk '{print $1}'`


rm -f $outputfile > /dev/null 2>&1

if [ $unexpected -gt 0 ] ; then
   echo "$unexpected node(s) reporting unexpected reboot ($down node(s) down)"
   exit 1
fi

if [ $down -gt 0 ] ; then
   echo "$down node(s) reporting down"
   exit 1
fi

# Add more conditions here


# Final condition
echo "Slurm okay - detected $totalnodes running node(s)"
exit 0
