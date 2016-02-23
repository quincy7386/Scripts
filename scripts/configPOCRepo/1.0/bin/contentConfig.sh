#!/bin/bash
#
# This script checks the age of the user supplied content then determines
# what type of appliance it is running on. The appropriate user supplied
# content is then installed.
# Written by Jon Nelson, jon.nelson@rsa.com, 11/7/2013


#///////////////////////////// Functions /////////////////////////////////////

# This function checks the age of the user supplied content and prompts the
# user to contuinue. It then finds the resource bundle and unzips it to
# the correct directory. This function requires that the mount point for
# the coontent thumb drive is passed as an argument
function contentChk () {
    # Variables
    cnt=0 
    total=0
    thumb=$1
   
    # Abort if we have no mount point
    if [ -z $thumb ]; then
        echo -e "\nERROR:  No mount point for content supplied"
        sleep 2
        exit 1
    fi

    # Get the epoch date for each file
    for i in $(ls -lcR $thumb | awk '{ print $6" "$7" "$8 }' | xargs -I {} date -d'{}' +%s); do 
        # Get numbers to determine the average
        total=$(($total+$i))
        ((cnt++))
    done
    # Determine the average
    avg=$(expr $total / $cnt | xargs -I {} date -d @'{}')
    # Figure out two moths ago
    twoMonthsAgo=$(date -d '2 months ago')
    # Clear the screen
    clear
    # Show them the average
    echo -n "The average date of your content is: "
    echo $avg
    # Determine is their content is older than two months
    if [ $(date -d "$avg" +%s) -lt $(date -d "$twoMonthsAgo" +%s) ]; then
        ltGt="MORE"
    else
        ltGt="LESS"
    fi
    # Show their age
    echo -e "It is also $ltGt than two months old.\n"
    # Let them choose to continue
    while [ 1 -eq 1 ]; do
        echo -n "Would you like to continue with the age of your content (y/n)? "
        read choice
        case "$choice" in
            y|Y)
                break
            ;;
            n|N)
                echo "Aborting..."
                sleep 2
                exit 1
            ;;
            *)
                echo "Incorrect input! Choose y or n."
                sleep 2
            ;;
        esac
    done       

    # Check for resource bundle zip file
    find $thumb -type f -iname "resourceBundle*.zip" -print | xargs -I file cp file /tmp/
    # Make a temp directory to store content
    mkdir /tmp/configPOC
    # Unzip the intial content
    unzip /tmp/resourceBundle*.zip -d /tmp/configPOC
    # Abort if the resource bundle wasn't found
    if [ $! -eq 0 ]; then
        echo "Content ZIP file not present. Aborting..."
        rm -rf /tmp/configPOC
        sleep 2
        exit 1
    fi
    # Find all the zips in the resource bundle and unzip them 
    find /tmp/configPOC -type f -iname "*.zip" -print -execdir unzip {} \; 
}

# This function determines what type of appliance it is running on and then
# applies the appropriate content. This function requires that the mount point for
# the coontent thumb drive is passed as an argument
function contentConfig () {
    # Variables
    thumb=$1
    cnt=0
    type=0
    services=( NwDecoder NwLogDecoder NwConcentrator NwBroker NwAppliance)
    
    # Abort if we have no mount point
    if [ -z $thumb ]; then
        echo "No mount point for content supplied"
        exit 1
    fi

    #Check to see which services are running 
    for i in "${services[@]}"; do
        # Count the number of hits for each service
        num=$(ps aux | grep $i | wc -l)
        # If its 2 then the service exists
        if [ $num -eq 2 ]; then
            # Keep a count to check for hybrids
            ((cnt++))
        fi
        # Check for log decoders
        if [ "$i" = "NwLogDecoder" ]; then 
            type=1
        elif [ "$i" = "NwConcentrator" || "$i" = "NwBroker" ]; then
            type=2
        fi
    done
    if [ $cnt -eq 4 ]; then
        # All the services were present
        echo "We got an AIO"
        allContent $thumb
    elif [[ $cnt -gt 1 && $type -gt 0 ]]; then
        # Log hybrid
        echo "We got a log hybrid"
        logDecoderContent $thumb
        concentratorContent $thumb
    elif [[ $cnt -gt 1 && $type -eq 0 ]]; then
        # Packet hybrid
        echo "We got a packet hybrid"
        packetDecoderContent $thumb
        concentratorContent $thumb
    elif [ $type -eq 0 ]; then
        # Packet Decoder
        packetDecoderContent $thumb
        echo "We got a packet decoder"
    elif [ $type -eq 1 ]; then
        # Log decoder
        echo "We got a log decoder"
        logDecoderContent $thumb
    elif [ $type -eq 2 ]; then
        # Concentrator
        echo "We got a concentrator or broker"
        concentratorContent $thumb
    else
        echo "Not sure what appliance this is...aborting"
        sleep 2
        exit 1
    fi
}

# This function applies all the content by calling other functions and scripts 
function allContent () {
    # Variables
    thumb=$1
    concentratorContent $thumb
    logDecoderContent $thumb
    packetDecoderContent $thumb
}

# This function applies the concentrator content
concentratorContent () {
    # Variables
    thumb=$1
    # Make folder to back up file
    if [ ! -e /etc/netwitness/ng/backups ]; then
        mkdir /etc/netwitness/ng/backups/{feeds,parsers}
    fi
    # Back up file
    mv /etc/netwitness/ng/index-concentrator-custom.xml /etc/netwitness/ng/backups
    # Copy index-concentrator-custom.xml
    find $thumb -type f -iname index-concentrator-custom.xml -print | xargs -I file cp file /etc/netwitness/ng/
}

# This function applies the log decoder content
logDecoderContent () {
    # Variables
    thumb=$1
    # Envision content
    # Copy NwDecoder.cfg
    # Copy aliases
    packetDecoderContent $thumb
}

# This function applies the packet decoder content
packetDecoderContent () {
    # Variables
    thumb=$1
    # copy NwDecoder.cfg
    # Check for content directory
    if [ ! -e /tmp/configPOC ]; then
        echo "Content not present on system! Aborting..."
        sleep 2
        exit 1
    fi
    # Make folder to back up file
    if [ ! -e /etc/netwitness/ng/backups ]; then
        mkdir -p /etc/netwitness/ng/backups/{feeds,parsers}
    fi
    # Back up files
    mv /etc/netwitness/ng/index-decoder-custom.xml /etc/netwitness/ng/backups
    mv /etc/netwitness/ng/feeds/* /etc/netwitness/ng/backups/feeds
    mv /etc/netwitness/ng/parsers/* /etc/netwitness/ng/backups/parsers

    # Copy index-decoder-custom.xml
    find $thumb -type f -iname index-decoder-custom.xml -print | xargs -I file cp file /etc/netwitness/ng/
    # Copy feeds
    find $thumb -type f -iwholename "*feed*" -print | xargs -I file cp file /etc/netwitness/ng/feeds/
    # Copy parsers
    find $thumb -type f -iwholename "*parser*" -print | xargs -I file cp file /etc/netwitness/ng/parsers/
    # Push rules
    # Check for app rule folder
    if [ -e /tmp/configPOC/APPRULE ]; then
        # Start count for rules
        cnt=0
        # Create curl statement for each rule found
        for i in $(find /tmp/configPOC/APPRULE/ -type f -iname *.nwr -print); do
            # Tell them what we are doing
            echo -n "Adding application rule $i: "
            # Count in decimal so printf works
            cnt=$((10#$cnt + 1))
            # Print four digits
            cnt=$(printf "%04d" "${cnt}")
            # Set current app rule
            curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/rules/application/$cnt?force-content-type=text/plain -d msg=set --data-urlencode value@$i 
        done
    fi
} 

#///////////////////////////// Main /////////////////////////////////////

echo "Preapring to load content from thumb drive"

# Call funtions with mount point to thumb drive
contentChk $1 
contentConfig $1
