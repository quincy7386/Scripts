#!/bin/bash
#
# Revision Notes
# Rev.1 Notes - Script configures SA appliance to be the Yum repository for other servers
# Rev.2 Notes - Updated Netwitness Repo, Added SA Repo, Added RSACorpCAv2.pem
# Rev.2 Notes - Script also sets up the main SA appliance to grab updates from Live
# Rev.2 Notes - Special Characters in passwords need the HEX %## equivalent (e.g. # = %23)
# Rev.2 Notes - Special Characters cross reference here http://www.asciitable.com/
# Rev.3 Notes - Added Menu Options & Logic for Using Live or Local repo for SA Server updates
#
# Revision Authors
# Rev.1 - Jon Nelson, jon.nelson@rsa.com, 11/5/2013
# Rev.2 - Chad Sturgill, chad.sturgill@rsa.com, 11/9/2013
# Rev.3 - Chad Sturgill, chad.sturgill@rsa.com, 11/13/2013

#//////////////////////// Functions ///////////////////////////

function show_menu(){
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"`
    ENTER_LINE=`echo "\033[33m"`
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU}**${NUMBER} 1)${MENU} Live Updates with SA as Internal Repo ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 2)${MENU} No Live Updates with SA as Internal Repo ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    read opt
}
function option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

# This function instructs users how to run the script
function useage0 () {
    if [ "$#" -lt "1" ]; then
        echo "Usage: $0 <SA server IP> <Optional Live UN> <Optional Live PW>"
        exit 1
    elif [ "$#" -gt "3" ]; then
        echo "Too many arguments!"
        echo "Usage: $0 <SA server IP> <Optional Live UN> <Optional Live PW>"
        exit 1
    fi
}

# This function checks for all 3 arguments
function useage1 () {
    if [ "$#" -lt "3" ]; then
        echo "Useage: $0 <SA server IP> <Optional Live UN> <Optional Live PW>"
		echo ""
		echo "Warning: Live account needs a username & password to function"
		echo "Warning: Continuing without username & password"
		echo ""
		echo "Note: Set Live credentials later with this script or web gui"
		echo ""
        read -p "Press [Enter] to continue..."
    elif [ "$#" -gt "3" ]; then
        echo "Too many arguments!"
        echo "Useage: $0 <SA server IP> <Optional Live UN> <Optional Live PW>"
        exit 1
    fi
}

# This function checks for argument
function useage2 () {
    if [ "$#" -lt "1" ]; then
        echo "Useage: $0 <SA server IP>"
        exit 1
    elif [ "$#" -gt "1" ]; then
        echo "Too many arguments!"
        echo "Useage: $0 <SA server IP>"
        exit 1
    fi
}

# This function creates a directory and stores the CentOS repo files in it
function createDir () {
    echo "Creating directory /etc/yum.repos.d/repos.oem..."
    # Does the directory exist?
    if [ -d /etc/yum.repos.d/repos.oem ]; then
        echo "Directory already exists..."
    else        
        # Create the directory
        mkdir /etc/yum.repos.d/repos.oem
        # Check it was successful
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Creating directory failed. Script aborting"
            exit 1
        fi
    fi
    echo "Moving old repo files..."
    # If the files exist, move them
    if [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
        mv /etc/yum.repos.d/Cent* /etc/yum.repos.d/repos.oem
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Moving files failed. Script aborting"
            exit 1
        fi
    else
        echo "No files to move..."
    fi
}

# This fuction creates the necessary netwitness.repo file
function createNWRepo () {
    echo "Creating netwitness.repo..."
    echo "[nwupdates]" >> /etc/yum.repos.d/netwitness.repo
    # Check the first write to the file
    if [ $? -eq 0 ]; then
        echo "Success"
    else
        echo "Creating file failed. Script aborting"
        exit 1
    fi
    echo "name=Netwitness-Updates-Repo" >> /etc/yum.repos.d/netwitness.repo
    echo "baseurl=http://$1/rsa/updates" >> /etc/yum.repos.d/netwitness.repo
    echo "enabled=0" >> /etc/yum.repos.d/netwitness.repo
    echo "gpgcheck=1" >> /etc/yum.repos.d/netwitness.repo
    echo "sslverify=1" >> /etc/yum.repos.d/netwitness.repo
	echo "sslcacert=/etc/pki/CA/certs/RSACorpCAv2.pem" >> /etc/yum.repos.d/netwitness.repo
}

# This fuction creates the necessary sa.repo file
function createSARepo () {
    echo "Creating sa.repo..."
    echo "[sa]" >> /etc/yum.repos.d/sa.repo
    # Check the first write to the file
    if [ $? -eq 0 ]; then
        echo "Success"
    else
        echo "Creating file failed. Script aborting"
        exit 1
    fi
    echo "name=SA Yum Repo" >> /etc/yum.repos.d/sa.repo
    echo "baseurl = https://$2:$3@smcupdate.emc.com/nw10/rpm" >> /etc/yum.repos.d/sa.repo
    echo "enabled=1" >> /etc/yum.repos.d/sa.repo
	echo "protect=0" >> /etc/yum.repos.d/sa.repo
    echo "gpgcheck=1" >> /etc/yum.repos.d/sa.repo
	echo "sslVerify=1" >> /etc/yum.repos.d/sa.repo
	echo "sslcacert = /etc/pki/CA/certs/RSACorpCAv2.pem" >> /etc/yum.repos.d/sa.repo
	echo "metadata_expire = 1d" >> /etc/yum.repos.d/sa.repo
    echo "failovermethod=priority" >> /etc/yum.repos.d/sa.repo
}

# This fuction creates the necessary RSACorpCAv2.pem file
function createRSACorpCAv2 () {
	rm -f /etc/pki/CA/certs/RSACorpCAv2.pem
    echo "Creating RSACorpCAv2.pem..."
    echo "Issuer ...: /CN=RSA Corporate CA v2/OU=Global Security Organization/O=RSA Security LLC/L=Bedford/ST=Massachusetts/C=US" >> /etc/pki/CA/certs/RSACorpCAv2.pem
    # Check the first write to the file
    if [ $? -eq 0 ]; then
        echo "Success"
    else
        echo "Creating file failed. Script aborting"
        exit 1
    fi
	echo "Serial ...: 009F6C8BD34B73594063E476D369FDFDFA" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "Subject ..: /CN=RSA Corporate Server CA v2/OU=Global Security Organization/O=RSA Security LLC/L=Bedford/ST=Massachusetts/C=US" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "-----BEGIN CERTIFICATE-----" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "MIIE/zCCA+egAwIBAgIRAJ9si9NLc1lAY+R202n9/fowDQYJKoZIhvcNAQEFBQAw" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "gZcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRzMRAwDgYDVQQH" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "EwdCZWRmb3JkMRkwFwYDVQQKExBSU0EgU2VjdXJpdHkgTExDMSUwIwYDVQQLExxH" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "bG9iYWwgU2VjdXJpdHkgT3JnYW5pemF0aW9uMRwwGgYDVQQDExNSU0EgQ29ycG9y" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "YXRlIENBIHYyMB4XDTExMDMxMDIxNDA1N1oXDTE5MDIyODIxNTYzM1owgZ4xCzAJ" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "BgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRzMRAwDgYDVQQHEwdCZWRm" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "b3JkMRkwFwYDVQQKExBSU0EgU2VjdXJpdHkgTExDMSUwIwYDVQQLExxHbG9iYWwg" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "U2VjdXJpdHkgT3JnYW5pemF0aW9uMSMwIQYDVQQDExpSU0EgQ29ycG9yYXRlIFNl" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "cnZlciBDQSB2MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMlEfyTA" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "hnX8JlErtRFUAIougscUT91SFwxYsDoqjuw1jOQPASUPcJDq4Axjje8kHwSlcpeB" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "23lehX+yutvWBXKRsr4Exu2ObkSYkrli2dpgl+LpLVAEnZaOikZLjHzXIeH6O79u" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "UsB0JZbvQ9B3X5q2IFrjLiB55Mc1IBNJY/Ebr4OU/HkvxB3GWmqeHL9uH2yC15CE" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "5iM+Za83+nuGulthVguBSeQWyAodvAKW5BE9W4XoYpMYuIzL5haiOz0fvgf2PbGo" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "44EVhrN1sxyi9qGEslRy4poXGXD3WQltVbOk6QlssKBTG9wOcVIiXO0t6RyuzXIn" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "sGX8pV3csrJdsDECAwEAAaOCATswggE3MA8GA1UdEwQIMAYBAf8CAQIwgZEGA1Ud" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "IASBiTCBhjCBgwYJKoZIhvcNBQcCMHYwLgYIKwYBBQUHAgEWImh0dHA6Ly9jYS5y" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "c2FzZWN1cml0eS5jb20vQ1BTLmh0bWwwRAYIKwYBBQUHAgIwODAXFhBSU0EgU2Vj" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "dXJpdHkgTExDMAMCAQEaHUNQUyBJbmNvcnBvcmF0ZWQgYnkgcmVmZXJlbmNlMEAG" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "A1UdHwQ5MDcwNaAzoDGGL2h0dHA6Ly9jcmwucnNhc2VjdXJpdHkuY29tL1JTQUNv" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "cnBvcmF0ZUNBdjIuY3JsMA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUKfPCY9Px" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "9Qulv7Jd32EQlDTPRwwwHwYDVR0jBBgwFoAUcxs4SyXLWo69AuzfXSn2EHQO2Jgw" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "DQYJKoZIhvcNAQEFBQADggEBAB7jJkSi8fSAIWG9bqsNzC0/6F3Vsism5BizSxtU" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "X8nTRHaCzYOLY2PnjieySxqVOofsCKrnGQpIeax2Vre8UHvIhU9fhzj2+n4LbmfJ" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "GcWCGk75CKTn/tWc8jemllyT/5pSQOtt+Qw6LJ6+sprJtnQ7st/e+PzG8MkLjNVl" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "U7WIrxCns2ZEbqHO/easHZ3rMu3jG4RfNa44r6zrU58TPQ3y3Tnwbo3vRrOvVOTG" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "2zJiPPbNMuFlAKmc2TYhODc0aDFUtdeskbc/SKcb5PvlQesG8J2PkktKAhoTxeFj" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "pvsXSNCQ5DpPyB/uGozgI8tgoNjDm11O57DCxZFQ6qPsIwI=" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "-----END CERTIFICATE-----" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	echo "" >> /etc/pki/CA/certs/RSACorpCAv2.pem
	chmod 744 /etc/pki/CA/certs/RSACorpCAv2.pem
}

# This fuction adds the requisite line to yum.conf
function add2YumConf () {
    echo "Editing /etc/yum.conf..."
    # Check if the line exists
    grep http_caching /etc/yum.conf
    if [ $? -eq 0 ]; then
        # If it exits give it the right setting
        sed -i.bak -e 's/^\(http_caching=\)\(.*$\)/\1none/' /etc/yum.conf
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    else
        # It doesn't exist, so add the line
        echo "http_caching=none" >> /etc/yum.conf
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    fi
}

# This fuction adds the requisite line to fastestmirror
function add2Fast () {
    echo "Editing /etc/yum/pluginconf.d/fastestmirror..."
    # Check if the line exists
    grep "^enabled=" /etc/yum/pluginconf.d/fastestmirror.conf
    if [ $? -eq 0 ]; then
        # If it exits give it the right setting
        sed -i.bak -e 's/^\(enabled=\)\(.*$\)/\10/' /etc/yum/pluginconf.d/fastestmirror.conf
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    else
        # It doesn't exist, so add the line
        echo "enable=0" >> /etc/yum/pluginconf.d/fastestmirror.conf
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    fi
}

# This function turns on local netwitness repo for SA updates
function setLocalrepoOn () {
    echo "Editing /etc/yum.repos.d/netwitness.repo"
    # Check if the line exists
    grep "^enabled=" /etc/yum.repos.d/netwitness.repo
    if [ $? -eq 0 ]; then
        # If it exits give it the right setting
        sed -i.bak -e 's/^\(enabled=\)\(.*$\)/\11/' /etc/yum.repos.d/netwitness.repo
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    else
        # It doesn't exist, so add the line
        echo "enable=1" >> /etc/yum.repos.d/netwitness.repo
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    fi
}

# This function turns off Live repo for SA updates
function setLiverepoOff () {
    echo "Editing /etc/yum.repos.d/sa.repo"
    # Check if the line exists
    grep "^enabled=" /etc/yum.repos.d/sa.repo
    if [ $? -eq 0 ]; then
        # If it exits give it the right setting
        sed -i.bak -e 's/^\(enabled=\)\(.*$\)/\10/' /etc/yum.repos.d/sa.repo
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    else
        # It doesn't exist, so add the line
        echo "enable=0" >> /etc/yum.repos.d/sa.repo
        if [ $? -eq 0 ]; then
            echo "Success"
        else
            echo "Editing file failed. Script aborting"
            exit 1
        fi
    fi
}

# This function runs all the yum commands
function yumUp () {
    yum clean all && yum check-update
    yum update
exit 1
}

# This function checks for sa.repo
function checkSARepo () {
if [ ! -f /etc/yum.repos.d/sa.repo ]; then
	createSARepo $1 $2 $3
else
	read -p "Do you want to delete and recreate sa.repo? [yn]" answer
	if [[ $answer = y ]] ; then
		rm -f /etc/yum.repos.d/sa.repo
		createSARepo $1 $2 $3
	else
	echo "File sa.repo remains unchanged"
	fi
fi
}

# This function checks for netwitness.repo
function checkNWRepo () {
if [ ! -f /etc/yum.repos.d/netwitness.repo ]; then
	createNWRepo $1
else
	read -p "Do you want to delete and recreate netwitness.repo? [yn]" answer
	if [[ $answer = y ]] ; then
		rm -f /etc/yum.repos.d/netwitness.repo
		createNWRepo $1
	else
	echo "File netwitness.repo remains unchanged"
	fi

fi
}

#//////////////////////// Main ///////////////////////////

# Check useage
useage0 $1 $2 $3

# Main selection menu
clear
show_menu $1 $2 $3
while [ opt != '' ]
    do
    if [[ $opt = "" ]]; then 
            exit;
    else
        case $opt in
        1) clear;
			option_picked "Option 1 Picked";
			useage1 $1 $2 $3 && checkSARepo $1 $2 $3 && checkNWRepo $1 $2 $3 && createDir && createRSACorpCAv2 && add2YumConf && add2Fast && yumUp; #Live Updates with SA as Internal Repo
        menu;
        ;;

        2) clear;
            option_picked "Option 2 Picked";
            useage2 $1 && checkSARepo $1 && checkNWRepo $1 && setLocalrepoOn && setLiverepoOff && createDir && createRSACorpCAv2 && add2YumConf && add2Fast && yumUp; #No Live Updates with SA as Internal Repo
        menu;
        ;;

        x)exit;
        ;;

        \n)exit;
        ;;

        *)clear;
			option_picked "Pick an option from the menu";
			show_menu;
        ;;
    esac
fi
done


