#!/bin/bash

# Witten by Jon S. Nelson, jnelson@carbonblack.com, (c) 2018
# The purpose of this script is to demostrate some of the coming capabilities of Live Query
# on the Linux platform.
#
# PREREQS:
# Centos7 VM
# root login
# osquery installed

  
# Clear the screen 
clear

echo "This script will demonstrate a security, compliance, and dev ops use case for Live Query."
echo -e "First the security use case: Looking for process only running in memory:\n"  

read -n1 -rsp $'\nPress any key to create eViL-ping in local directory or Ctrl+C to exit...\n'
# Make local copy of ping
cp `which ping` eViL-ping

# Start eViL-ping with no output in the background
echo -e "\neViL-ping process created in local directory..."
echo "ls -l eViL-ping"
ls -l eViL-ping
read -n1 -rsp $'\nPress any key to execute eViL-ping or Ctrl+C to exit...\n'
echo -e "\nExecuting eViL-ping..."
./eViL-ping 8.8.8.8 > /dev/null &
# Show process is running
echo "ps -C eViL-ping"
ps -C eViL-ping

read -n1 -rsp $'\nPress any key to delete eViL-ping from the filesystem or Ctrl+C to exit...\n'
echo -e "\nDeleting eViL-ping..."
# Delete eViL-ping
echo "rm -f ./eViL-ping"
rm -f ./eViL-ping
echo "ls -l eViL-ping"
ls -l eViL-ping

# Use osqueryi to show process running only in memory
read -n1 -rsp $'\nPress any key to run a query to look for processes running only in memory...\n'
echo "SELECT name, path, pid FROM processes WHERE on_disk = 0;"
osqueryi "SELECT name, path, pid FROM processes WHERE on_disk = 0;"
# Kill the process
kill $(ps -C eViL-ping | awk '$1 ~ /[0-9]+/ { print $1 }')

echo -e "\n\nNext for the compliance use case: Looking for hosts whose primary disk is currently unencrypted."
read -n1 -rsp $'\nPress any key to run query...\n'
echo -e "SELECT * FROM mounts m, disk_encryption d"
echo -e "\tWHERE m.device_alias = d.name"
echo -e "\tAND m.path = "/""
echo -e "\tAND d.encrypted = 0;\n"

osqueryi 'SELECT * FROM mounts m, disk_encryption d WHERE m.device_alias = d.name AND m.path = "/" AND d.encrypted = 0;'

echo -e "\n\nNext for the dev ops use case: Looking for hosts where root has logged in in the last hour."
read -n1 -rsp $'\nPress any key to run query...\n'
echo -e "SELECT * FROM last"
echo -e "\tWHERE username = "root""
echo -e "\tAND time > (( SELECT unix_time FROM time ) - 3600 );\n"
osqueryi 'SELECT * FROM last WHERE username = "root" AND time > (( SELECT unix_time FROM time ) - 3600 );'

