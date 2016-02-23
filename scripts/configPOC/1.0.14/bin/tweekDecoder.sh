#!/bin/bash
#
# This script optimizes the decoder's configuration via the REST API and 
# some command line utilities.
# Written by Jon S. Nelson, jon.nelson@rsa.com, 2013

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
curl -s -u admin:netwitness http://127.0.0.1:50104/sdk/config/packet.read.throttle -d msg=set -d value=1 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /decoder/config/packet.read.throttle = 1"
else
    echo "Error setting /decoder/config/packet.read.throttle... Aborting"
    exit 1 
fi
curl -s -u admin:netwitness http://127.0.0.1:50104/sdk/config/max.concurrent.queries -d msg=set -d value=8 | grep -i success > /dev/null
if [ $? -eq 0 ]; then 
    echo "Success setting /sdk/config/max.concurrent.queries = 8"
else
    echo "Error setting /sdk/config/max.concurrent.queries... Aborting"
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

