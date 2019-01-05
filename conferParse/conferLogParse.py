
# coding: utf-8

# In[84]:


import argparse
import re
fileIn = ""
fileOut = ""

reasons = {
    0x800000:"Create Application",
    0x400000:"Modify System Executable",
    0x200000:"Modify System Config",
    0x100000:"Invoke Not Trusted",
    0x80000:"Invoke Kernel Access",
    0x40000:"Invoke Command Interpreter",
    0x20000:"Invoke another application",
    0x10000:"Invoke System Utility",
    0x8000:"User Doc",
    0x4000:"Credential",
    0x2000:"Use Keyboard Input",
    0x1000:"Use Microphone or Camera",
    0x800:"Ransomware-like behavior",
    0x400:"Communicate over the network - peer",
    0x200:"Communicate over the network - as server",
    0x100:'Communicate over the network - as client',
    0x80:"Inject code",
    0x40:"Scraping Memory",
    0x20:"Buffer Overflow",
    0x10:"Has Pack code",
    0x8:"Impersonate",
    0x4:"Escalated Users Rights",
    0x2:"Run as Admin",
    0x1:"Tries to run or is running"
    }

def getArgs():
    parser = argparse.ArgumentParser(description='Translates TERMINATE and DENY policy IDs in a confer.log file.')
    parser.add_argument('-i', '--fileIn', help='confer.log to read from', required=True)
    parser.add_argument('-o', '--fileOut', help='output file to write to', required=True)
    args = parser.parse_args()
    global fileIn, fileOut
    fileIn = args.fileIn
    fileOut = args.fileOut

# Get all the the hex IDs for the TERMINATE or DENY reasons
# Requires the listed policy hex ID
def getKeys(value):
    keys = []
    value = int(value, 16)
    # Iterate over all the reason keys
    for reasonKey in reasons:
        # If the key is less than the value...
        if reasonKey <= value:
            # subtract it...
            value = value - reasonKey
            # and save the key
            keys.append(hex(reasonKey))
            # Stop when we hit zero
            if value == 0:
                return keys
# end getKeys()

# Get the reasons associated with the keys
# Requires getKeys() list and TERMINATE or DENY ID
def getReasons(keys, policy):
    reasonsOut = [policy]
    # Iterate over the keys
    for key in range(len(keys)):
        # Cast strings to hex
        hexKey = int(keys[key], 16)
        # Seperate with a comma if more than one
        reasonsOut.append(",")
        # Add to the list
        reasonsOut.append(reasons[hexKey])
    return reasonsOut
# end getReasons()

# Reads policy lines from confer.log and finds TERMINATE or DENY instances.
# Writes policy line with reason translations to file
def getPolicyLines():
    # Open file for reading
    with open(fileIn, encoding = "ISO-8859-1") as fIn:
        # Open file for writing
        with open(fileOut, "w", encoding = "ISO-8859-1") as fOut:      
            # Loop over the input file
            for line in fIn:
                # Initialize variable
                policy = "NONE"
                # Look for policy lines
                exp = re.match('^.*policy \(.*', line)
                if exp:
                    # Initialize variable
                    policyOut = []
                    # Look for DENY policies
                    exp = re.match('^.*policy \(0x0, (0x[1-9a-f][0-9a-f]{0,5}),.*', line)
                    if exp:
                        # Set policy type
                        policy = "DENY"
                        # Get all the the hex IDs for the reason
                        keys = getKeys(exp.group(1))
                        # Decode the hex IDs
                        deny = (getReasons(keys, policy))
                        # Add them to our output variable
                        policyOut.append("".join(deny))
                    # Look for TERMINATE with and without DENYs
                    exp = re.match('^.*policy \(0x0, 0x[0-9a-f]{1,6}, 0x0, (0x[1-9a-f][0-9a-f]{0,5}),.*', line)
                    if exp:
                        # Set policy type
                        policy = "TERMINATE"
                        # Get all the the hex IDs for the reason
                        keys = getKeys(exp.group(1))
                        # Decode the hex IDs
                        terminate = getReasons(keys, policy)
                        # Add them to our output variable
                        policyOut.append("".join(terminate))
                # Write to output file if we have a TERMINATE or DENY
                if policy != "NONE":
                    # Add the line to the output variable
                    policyOut.insert(0, line.rstrip('\n'))
                    # Write output
                    fOut.write(','.join(policyOut) + '\n')
# end getPolicyLines()          
#
#-------------------------------
#
# main

getArgs()
getPolicyLines()


