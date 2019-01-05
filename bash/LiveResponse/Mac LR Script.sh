#!/bin/bash

name=evindence-$(date)
host=$(hostname)
dir=$host"-"$name
out=$dir.txt
mkdir $dir


declare -a cmds=("date" "hostname" "iostat" "uptime" "w" "df" "grep -v nologin /etc/passwd" "lsof" "who -a" "last" "ps aux" "uname -a" "sw_vers" "lsof -nP -i:1-65535" "netstat -r" "arp -an" "ndp -an" "ifconfig -a" "find /Applications/ /System/ /Users/ /usr/ /bin/  -perm u=s,g=s")
for i in "${cmds[@]}";do 
    echo -e "\n$i"  >> "$out"
    printf '=%.0s' {1..100} >> "$out" 
    echo -e "\n" >> "$out"
    eval "$i" | tee -a "$out" "$dir/$i.txt" 
done
