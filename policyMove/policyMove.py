# ***** DISCLAIMER ******
# This script is a proof of concept, and has not been tested in a production enviroment.

# This script takes a CSV file with hostnames all on one line. All those hosts are then moved
# to the chosen policy if they are active/registered in Cb Defense. 
#
# Before running the script change the "hosts" and "policy" variables to your liking. You will
# also need to create a Cb Defense credtials file: https://cbapi.readthedocs.io/en/latest/#api-credentials

# Written by Jon S. Nelson, jnelson@carbonblack.com, (C) 2018

# Imports
from cbapi.defense.models import *
from cbapi.defense import *
import csv

#Variables
# All host on a single line. Names are case sensitive.
hosts = "test.csv" 
# Policy to move host to
policy = "Monitored"

# Create our Cb Defense API object
# To do this you need to have created you credtials file
# https://cbapi.readthedocs.io/en/latest/#api-credentials
cb = CbDefenseAPI(profile="live")

# Open the CSV
with open(hosts, newline='') as csvfile:
    # Parse the CSV
    reader = csv.reader(csvfile)
    # Look at the data
    for row in reader:
        # Intialize counter
        cnt = 0
        # Iterate over each element (host)
        while cnt < len(row):
            host = row[cnt]
            # Get device object for specific host
            devices = cb.select(Device).where("hostNameExact:" + host)
            # Change the policy
            for dev in devices:
                # Make sure the sensor is active
                if dev.status == "REGISTERED":
                    # Move them to the policy
                    dev.policyName = policy
                    dev.save()
                    # Tell them what we did
                    print("Moved " + host + " with Device ID " + str(dev.deviceId) + " to the " + policy + " policy" )
            # Increment the counter
            cnt += 1
            
