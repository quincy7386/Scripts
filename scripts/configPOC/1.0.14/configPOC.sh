#!/bin/bash
#
# This script is the main interface into the POC configuration scripts, which.
# are located in the bin directory. It has two fuctions that get the proper 
# information to run the subscripts. This script prompts the user for one of 
# five options and then executes the appropriate subscripts.
# Written by Jon S. Nelson, jon.nelson@rsa.com, 2013

///////////////////////////// Functions ////////////////////////////////// 

# This function prompts the user for the mount point for the thumb drive
# containing the custom content and checks to make sure it exists.
function getMount () {
    echo -e "Here are the current mount points:\n"
    mount
    echo -en "\nPlease enter the mount point for the thumb drive (e.g., /mnt/thumb): "
    read mountPt
    if [ ! -e $mountPt ]; then
        "Mount point does not exist. Aborting..."
        sleep 2
        exit 1
    fi
}

# This fuction prompts the user for the required input values for the yum
# configuration script.
function getYumOpts () {
    clear
    echo "Preparing to configure yum..."
    echo -n "Enter the SA Server IP: "
    read SAIP
    echo -n "Enter optional Live user name: "
    read liveUser 
    echo -n "Enter optional Live user password: "
    read livePass 
}


///////////////////////////// Main ////////////////////////////////// 

# Global variable
mountPt

# Infinite loop
while [ 1 -eq 1 ]; do
    # Clear the screen
    clear
    # Menu items
    cat version.txt
    echo "1) New Decoder/Concentrator/Hybrid full usb install" 
    echo "2) New Decoder/Concentrator/Hybrid content only"
    echo "3) New Decoder/Concentrator/Hybrid networking only"
    echo "4) New S4 Decoder/Concentrator/Hybrid optimize only"
    echo "5) Configure yum repositories (local/Live)"
    echo -e "Q) Quit\n"
    echo -n "Choose an action (1-5): "
    read action
    # Execute their choice
    case "$action" in
                1)
                    # Configure the network or die trying
                    ./bin/netConfig.sh
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                    getYumOpts
                    # Configure yum or die trying
                    ./bin/yumConfig.sh $SAIP $liveUser $livePass
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                    # Tweek the decoder or die trying
                    ./bin/tweekDecoder.sh
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                    getMount                    
                    # Load custom content or die trying
                    ./bin/contentConfig.sh $mountPt
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                ;;
                2)
                    getMount
                    # Load custom content or die trying
                    ./bin/contentConfig.sh $mountPt
break
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                ;;
                3)
                    # Configure the network or die trying
                    ./bin/netConfig.sh
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                ;;
                4)
                    # Tweek the decoder or die trying
                    ./bin/tweekDecoder.sh
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                ;;
                5)    
                    getYumOpts
                    # Configure yum or die trying
                    ./bin/yumConfig.sh $SAIP $liveUser $livePass
                    if [ $? -eq 1 ]; then
                        exit 1
                    fi
                ;;
                q|Q)
                    echo "Exiting..."
                    exit 0
                ;;
                *)
                    echo "Incorrect choice! Choose again..."
                    sleep 1
               ;;
    esac
done
