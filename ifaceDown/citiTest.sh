#!/bin/bash
# written by Jon S. Nelson, jon.nelson@rsa.com (c)2016

# This script was designed to shut down interfaces listed 
# in ifaceDown.conf in CSV format. The first part of the
# script will shut down the interfaces are up initially.
# The second part will loop looking for the interfaces to
# come up and shut them down again before exiting.
#
# This script is designed to start from an upstart script 
# when the nwdecoder service starts.
#
# The script and conf file must be in a world readable dir, 
# so not /root

# Initialize counter
i=0

# Get interfaces to shut down
IFS=, read -r -a ifaces < /etc/citi/ifaceDown.conf

# Shut them down initially
while [ $i -lt ${#ifaces[@]} ]; do
	# Shut it down
    ifconfig ${ifaces[$i]} down
    # Increment to move to next interface
    ((i++))
done

# Reset counter
i=0

# Iterate through interfaces until all are shut down
# Will constantly loop until all interfaces from config 
# file are shut down 
while [ $i -lt ${#ifaces[@]} ]; do
    ifconfig | grep ${ifaces[$i]}
    # If the interface is up
    if (($? < 1)); then
        # Shut it down
        ifconfig ${ifaces[$i]} down
        # Increment to move to next interface
        ((i++))
    fi
done

