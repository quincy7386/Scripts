#!/bin/bash
# Collect data.
# Mostly taken from https://github.com/rshipp/ir-triage-toolkit/blob/master/linux/run 
#
# This script does some basic IR data collection from Linux endpoints.
#
# If you are not using the GEN4 Server 2012 R2 - High Enforcement VM, you will need
# to edit the mount.cifs line below to include your IP, share, user:pass.
#
# Useage: sh linuxLiveResponse.sh <evidence_folder>
#
# For the "evidence_folder" above, this is a folder on your Linux VM. If it doesn't 
# exist, it will be created for you. If you don't enter it on the commandline you 
# will be prompted for it by the script. 


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

# Mount hte dir for the files. This is done so the demo doesn't look complicated
mount.cifs //192.168.230.3/DemoShare/forensics $savedir -o user=admin,password=bit9se#

# Create directory structure.
saveto="$savedir/$(hostname)-$(date +%Y.%m.%d-%H.%M.%S)"
mkdir -p "$saveto"
logfile="$saveto/log.txt"

log() {
  echo "$(date +"%b %d %H:%M:%S") $(hostname) irscript: $1" | tee -a "$logfile"
}

# Start the log.
echo -n > "$logfile"
log "${bold}# Incident response volatile data collection script.${normal}"
log "${bold}# Starting data collection...${normal}"

# 1. Acquire a full memory dump.
# Done with Live Response and will be added to archive

# 2. Collect network information.
log "${bold}# Collecting network information...${normal}"
log "netstat -ap > $saveto/network.txt 2>&1"
netstat -ap > "$saveto/network.txt" 2>&1
             
# 3. Collect information about opened files and running processes.
log "${bold}# Collecting information about opened files and running processes.${normal}"
log "lsof > $saveto/opened_files.txt 2>&1"
lsof > "$saveto/opened_files.txt" 2>&1

# 4. Collect user/system information.
log "${bold}# Collecting user/system information.${normal}"
log "w > $saveto/users_w.txt 2>&1"
w > "$saveto/users_w.txt" 2>&1
log "who > $saveto/users_who.txt 2>&1"
who > "$saveto/users_who.txt" 2>&1
log "id > $saveto/users_id.txt 2>&1"
id > "$saveto/users_id.txt" 2>&1
log "uname -a > $saveto/system_uname.txt 2>&1"
uname -a > "$saveto/system_uname.txt" 2>&1
log "# Dumping kernel message buffer (dmesg)."
log "dmesg > $saveto/system_dmesg.txt 2>&1"
dmesg > "$saveto/system_dmesg.txt" 2>&1

# 5. Collect device information.
log "${bold}# Collecting information about currently mounted devices.${normal}"
log "mount > $saveto/mounted_devices.txt 2>&1"
mount > "$saveto/mounted_devices.txt" 2>&1

# Create checksums for all files
log "${bold}# Creating checksums (sha256sum) for all files.${normal}"
log "sha256sum $saveto/* > $saveto/sha256sums.txt"
sha256sum "$saveto/"* > "$saveto/sha256sums.txt"
log "sed -i 's/^.*sha256sums.txt.*$//; s/^.*log.txt.*$//' $saveto/sha256sums.txt"
sed -i 's/^.*sha256sums.txt.*$//; s/^.*log.txt.*$//' "$saveto/sha256sums.txt"

log "${bold}# All tasks completed. Exiting.${normal}"

# Unmount the file share
umount $savedir
