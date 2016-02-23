#!/bin/bash
#
# This script optimizes the decoder's configuration via the REST API and 
# some command line utilities.
# Written by Jon S. Nelson, jon.nelson@rsa.com, 2013
echo "Which capture interface to you want to test (eth0, em1, etc.)? "
read iface
echo "Tweeking the decoder in progress"
echo "Inspecting 20000 packets. Please stand by..."
# Get largest packet length
packetLen=$(tcpdump -c 20000 -enni $iface | awk '{ sub(/:/, "", $9); if( $9 > 1500) print $9 }' | uniq | sort | head -n 1)
# Check if packetLen is NULL
if [ -z $packetLen ]; then
    packetLen=1500
fi
# Set snaplength to propper size
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/capture.device.params -d msg=set -d value=snaplen=$packetLen | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/capture.device.params = snaplen=$packetLen"
else
    echo "Error setting /decoder/config/capture.device.params... Aborting"
    exit 1 
fi

# Tweeks from Duncan Slade's decoder tuning guide
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/assembler.session.pool -d msg=set -d value=700000 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/assembler.session.pool = 700000"
else
    echo "Error setting /decoder/config/assembler.session.pool... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/assembler.size.max -d msg=set -d value=32%20MB | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/assembler.size.max = 32 MB"
else
    echo "Error setting /decoder/config/assembler.size.max... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/capture.buffer.size -d msg=set -d value=128%20MB | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/decoder/config/capture.buffer.size = 128 MB"
else
    echo "Error setting /decoder/config/capture.buffer.size... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/pool.packet.page.size -d msg=set -d value=32%20KB | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/pool.packet.page.size = 32 KB"
else
    echo "Error setting /decoder/config/pool.packet.page.size... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/pool.packet.pages -d msg=set -d value=1000000 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/pool.packet.pages = 1000000"
else
    echo "Error setting /decoder/config/pool.packet.pages... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/pool.session.page.size -d msg=set -d value=8%20KB | grep -i success 
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/pool.session.page.size = 8 KB"
else
    echo "Error setting /decoder/config/pool.session.page.size... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/pool.session.pages -d msg=set -d value=200000 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/pool.session.pages = 200000"
else
    echo "Error setting /decoder/config/pool.session.pages... Aborting"
    exit 1 
fi

# Jim Hollar's tweeks
curl -s -u admin:netwitness http://127.0.0.1:50104/sdk/config/cache.window.minutes -d msg=set -d value=10 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/cache.window.minutes = 10"
else
    echo "Error setting /decoder/config/cache.window.minutes... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/sdk/config/max.concurrent.queries -d msg=set -d value=8 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /sdk/config/max.concurrent.queries = 8"
else
    echo "Error setting /sdk/config/max.concurrent.queries... Aborting"
    exit 1 
fi


#Increase the Centos VM reserved memory
echo 1048576 > /proc/sys/vm/min_free_kbytes
if [ $? -eq 0 ]; then 
    echo "Success setting /proc/sys/vm/min_free_kbytes = 1048576"
else
    echo "Error setting /proc/sys/vm/min_free_kbytes... Aborting"
    exit 1 
fi

#Increase the Centos VM reserved memory
echo vm.min_free_kbytes=1048576 >> /etc/sysctl.conf
if [ $? -eq 0 ]; then 
    echo "Success setting vm.min_free_kbytes=1048576 in /etc/sysctl.conf"
else
    echo "Error writing to /etc/sysctl.conf... Aborting"
    exit 1 
fi

# Turn off generic receive offload
ethtool -K em1 gro off
ethtool -K em2 gro off
ethtool -K em3 gro off
ethtool -K em4 gro off
echo /sbin/ethtool -K em1 gro off >> /etc/rc.local
echo /sbin/ethtool -K em2 gro off >> /etc/rc.local
echo /sbin/ethtool -K em3 gro off >> /etc/rc.local
echo /sbin/ethtool -K em4 gro off >> /etc/rc.local

echo "Done tweaking the decoder. Hit <Enter> to continue..."
read

