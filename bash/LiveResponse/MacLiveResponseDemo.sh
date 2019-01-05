#!/bin/bash
#
# This script does some basic IR data collection from Mac endpoints.
#
# Useage: sh MacLiveResponseDemo.sh <evidence_folder>
#
# For the "evidence_folder" above, this is a folder on the endpoint. If it doesn't 
# exist, it will be created for you. If you don't enter it on the commandline you 
# will be prompted for it by the script. 
# Mostly taken from https://github.com/rshipp/ir-triage-toolkit/blob/master/linux/run, 
# but the rest is written by Jon S. Nelson, jnelson@carbonblack.com


# For bolding text in output
bold=$(tput bold)
normal=$(tput sgr0)

# Make sure we're root.
[[ $UID == 0 || $EUID == 0 ]] || (
  echo "Must be root!"
  exit 1
  ) || exit 1

# Where should we store the data? 
savedir=$1
if ! [[ -n $savedir ]]; then
  echo -n "Directory to store data: "
  read savedir
  [[ -d $savedir ]] || mkdir -p "$savedir" || (
    echo "Not a valid directory."
    exit 1
    ) || exit 1
fi

# Create directory structure.
saveto="$savedir/$(hostname)-$(date +%Y.%m.%d-%H.%M.%S)"
mkdir -p "$saveto"
logfile="$saveto/log.txt"

log() {
  echo "$(date +"%b %d %H:%M:%S") $(hostname) irscript: $1" | tee -a "$logfile"
}

# 1. Start the log.
echo -n > "$logfile"
log "${bold}# Incident response volatile data collection script.${normal}"
log "${bold}# Starting data collection...${normal}"


# 2. Collect network information.
log "${bold}# Collecting network information...${normal}"
log "ifconfig -a > $saveto/interfaces.txt 2>&1"
ifconfig -a > "$saveto/interfaces.txt" 2>&1
log "lsof -nP -i:1-65535 > $saveto/network.txt 2>&1"
lsof -nP -i:1-65535 > "$saveto/network.txt" 2>&1
log "netstat -r > $saveto/route.txt 2>&1"
netstat -r > "$saveto/route.txt" 2>&1
log "arp -an > $saveto/arp.txt 2>&1"
arp -an > "$saveto/arp.txt" 2>&1
log "ndp -an > $saveto/IPV6-neighbors.txt 2>&1"
ndp -an > "$saveto/IPV6-neighbors.txt" 2>&1
log "ifconfig -a > $saveto/interfaces.txt 2>&1"
lsof -nP -i:1-65535 > "$saveto/interfaces.txt" 2>&1

             
# 3. Collect information about opened files and running processes.
log "${bold}# Collecting information about opened files and running processes.${normal}"
log "lsof > $saveto/opened_files.txt 2>&1"
lsof > "$saveto/opened_files.txt" 2>&1

# 4. Collect user/system information.
log "${bold}# Collecting user/system information.${normal}"
log "w > $saveto/users_w.txt 2>&1"
w > "$saveto/users_w.txt" 2>&1
log "who -a > $saveto/users_who.txt 2>&1"
who -a > "$saveto/users_who.txt" 2>&1
log "ifconfig -a > $saveto/last.txt 2>&1"
last > "$saveto/last.txt" 2>&1
log "id > $saveto/users_id.txt 2>&1"
id > "$saveto/users_id.txt" 2>&1
log "grep -v nologin /etc/passwd > $saveto/interactive-logins.txt 2>&1"
grep -v nologin /etc/passwd > "$saveto/interactive-logins.txt" 2>&1
log "uptime > $saveto/uptime.txt 2>&1"
uptime > "$saveto/uptime.txt" 2>&1
log "uname -a > $saveto/system_uname.txt 2>&1"
uname -a > "$saveto/system_uname.txt" 2>&1
log "dmesg > $saveto/system_dmesg.txt 2>&1"
dmesg > "$saveto/system_dmesg.txt" 2>&1
log "iostat > $saveto/iostat.txt 2>&1"
iostat > "$saveto/iostat.txt" 2>&1
log "ps aux > $saveto/ps-aux.txt 2>&1"
ps aux > "$saveto/ps-aux.txt" 2>&1

# 5. Collect device information.
log "${bold}# Collecting information about currently mounted devices.${normal}"
log "mount > $saveto/mounted_devices.txt 2>&1"
mount > "$saveto/mounted_devices.txt" 2>&1
log "df > $saveto/df.txt 2>&1"
df > "$saveto/df.txt" 2>&1

# 6. Collect certain files
log "${bold}# Collecting certain files from the filesystem.${normal}"
for i in $(ls /Users 2>/dev/null);do 
    tar rvf "$saveto".tar /Users/$i/.{bash_history,bash_sessions,bashrc,bash_profile} /Library/Preferences/com.apple.loginwindow.plist /System/Library/LaunchAgents/ 


# Create checksums for all files
log "${bold}# Creating checksums (sha256sum) for all files.${normal}"
log "shasum -a 256 $saveto/* > $saveto/sha256sums.txt"
shasum -a 256 "$saveto/"* > "$saveto/sha256sums.txt"


# Create an archive of all the data
log "${bold}# Creating an archive all files.${normal}"
tar rvf "$saveto".tar "$saveto"
gzip -S .gz "$saveto".tar

log "${bold}# All tasks completed. Exiting.${normal}"



