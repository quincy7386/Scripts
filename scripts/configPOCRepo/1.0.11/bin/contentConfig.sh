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
# the content thumb drive is passed as an argument
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

    # Find all the zips
    for file in $(find $thumb -type f -iname '*.zip' -print); do
        # Get the epoch date for each file
        for i in $(unzip -l $file | awk '{ print $2 }' | grep '[0-9]\{4,4\}$' | awk -F '-' '{ print $3"-"$1"-"$2 }' | xargs -I {} date -d'{}' +%s); do
            # Get numbers to determine the average
            total=$(($total+$i))
            ((cnt++))
        done
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
    find $thumb -type f -iname "*.zip" -print | xargs -I file cp -u file /tmp/
    # Make a temp directory to store content
    mkdir /tmp/configPOC
    # Unzip the intial content
    unzip /tmp/*.zip -d /tmp/configPOC
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
    NwDec=0
    NwLD=0
    NwCon=0
    NwBrok=0
    services=( NwDecoder NwLogDecoder NwConcentrator NwBroker)
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
            # Record services present
            if [ "$i" = "NwDecoder" ]; then 
                NwDec=1
            elif [ "$i" = "NwConcentrator" ]; then
                NwCon=1
            elif [ "$i" = "NwLogDecoder" ]; then
                NwLD=1
            elif [ "$i" = "NwBroker" ]; then
                NwBrok=1
            fi
        fi
    done
    if [[ $NwCon -gt 0 && $NwBrok -gt 0 ]]; then
        # All the services were present
        echo "We got an AIO"
        allContent $thumb
    elif [[ $NwLD -gt 0 && $NwCon -gt 0 ]]; then
        # Log hybrid
        echo "We got a log hybrid"
        logDecoderContent $thumb
        concentratorContent $thumb
        brokerContent $thumb
    elif [[ $NwDec -gt 0 && $NwCon -gt 0 ]]; then
        # Packet hybrid
        echo "We got a packet hybrid"
        packetDecoderContent $thumb
        concentratorContent $thumb
        brokerContent $thumb
    elif [[ $NwDec -gt 0 ]]; then
        # Packet Decoder
        packetDecoderContent $thumb
        echo "We got a packet decoder"
    elif [[ $NwLD -gt 0 ]]; then
        # Log decoder
        echo "We got a log decoder"
        logDecoderContent $thumb
    elif [[ $NwCon -gt 0 ]]; then
        # Concentrator
        echo "We got a concentrator"
        concentratorContent $thumb
    elif [[ $NwBrok -gt 0 ]]; then
        # Broker
        echo "We got a broker"
        brokerContent $thumb
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
    brokerContent $thumb
}

# This function applies the concentrator content
concentratorContent () {
    # Variables
    thumb=$1

    # Tell them what we are doing
    echo "Backing up and pushing concentrator content..."
    sleep 2
    # Make folder to back up file
    if [ ! -e /etc/netwitness/ng/backups ]; then
        mkdir /etc/netwitness/ng/backups/{feeds,parsers}
    fi
    # Back up file
    cp -u /etc/netwitness/ng/index-concentrator-custom.xml /etc/netwitness/ng/backups
    if [ -e $thumb/index-concentrator-custom.xml ]; then
        # Sync index-concentrator-custom.xml
        cp -u $thumb/index-concentrator-custom.xml /etc/netwitness/ng/backups/      else
        find /tmp/configPOC -type f -iname index-concentrator-custom.xml -print | xargs -I file cp -u file /etc/netwitness/ng/
    fi
}

# This function applies the log decoder content
logDecoderContent () {
    # Variables
    thumb=$1
    # Envision content
    # Copy NwDecoder.cfg
    # Copy aliases
    # Tell them what we are doing
    echo "Backing up and pushing log decoder content..."
    sleep 2
    packetDecoderContent $thumb
}

# This function applies the packet decoder content
packetDecoderContent () {
    # Variables
    thumb=$1

    # Tell them what we are doing
    echo "Backing up and pushing packet decoder content..."
    sleep 2

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
    cp -u /etc/netwitness/ng/index-decoder-custom.xml /etc/netwitness/ng/backups
    cp -u /etc/netwitness/ng/feeds/* /etc/netwitness/ng/backups/feeds
    cp -u /etc/netwitness/ng/parsers/* /etc/netwitness/ng/backups/parsers

    if [ -e $thumb/index-decoder-custom.xml ]; then
        # Sync index-decoder-custom.xml
        cp -u $thumb/index-decoder-custom.xml /etc/netwitness/ng/backups/
    else
        find /tmp/configPOC -type f -iname index-decoder-custom.xml -print | xargs -I file cp -u file /etc/netwitness/ng/
    fi
    # Copy feeds
    find /tmp/configPOC -type f -iwholename "*feed*" -print | xargs -I file cp -u file /etc/netwitness/ng/feeds/
    # Copy parsers
    find /tmp/configPOC -type f -iwholename "*parser*" -print | xargs -I file cp -u file /etc/netwitness/ng/parsers/
 
    # Push rules
    # Intialize count
    cnt=0
    echo "Starting to push application rules..."
    # Process nwr files with multiple lines
    for i in $(find $thumb -type f -iname "*.nwr"); do 
        for line in $(grep "type=application" $i); do
            ((cnt++))
            # Clear errors
            err=""
            # Process rule
            err=$(curl -s -u admin:netwitness http://192.168.1.113:50104/decoder/config/rules/application/?force-content-type=text/plain -d msg=merge --data-urlencode name=$i | grep -o 400)
            # Check for error and the write broken rule to file
            if [[ $err == "400" ]]; then
                echo $i >> nwrParseErrors.log
            fi
        done
    done
    # Determine if processing was successfull
    if [[ $cnt -gt 0 && ! -e ./nwrParseErrors.log ]]; then
        echo "All application rules successfully processed"
    elif [[ $cnt -gt 0 && -e ./nwrParseErrors.log ]]; then
        echo "Application rules processed with some errors. Review nwrParseErrors.log for rules not processed"
    else
        echo "No application rules to process..."
    fi
    #Pause for them to read the message
    echo "Hit Enter to continue..."
    read
       
    # Check for correlation rule folder
    if [ -e /tmp/configPOC/CORRULE ]; then
        # Start count for rules
        cnt=0
        # Create curl statement for each rule found
        for i in $(find /tmp/configPOC/CORRULE/ -type f -iname *.nwr -print); do
            # Tell them what we are doing
            echo -n "Adding correlation rule $i: "
            # Count in decimal so printf works
            cnt=$((10#$cnt + 1))
            # Print four digits
            cnt=$(printf "%04d" "${cnt}")
            # Set current app rule
            curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/rules/correlation/$cnt?force-content-type=text/plain -d msg=set --data-urlencode value@$i 
        done
    else
        echo "No correlation rules to process..."
        sleep 1
    fi
    # Check for network rule folder
    if [ -e /tmp/configPOC/NETRULE ]; then
        # Start count for rules
        cnt=0
        # Create curl statement for each rule found
        for i in $(find /tmp/configPOC/NETRULE/ -type f -iname *.nwr -print); do
            # Tell them what we are doing
            echo -n "Adding network rule $i: "
            # Count in decimal so printf works
            cnt=$((10#$cnt + 1))
            # Print four digits
            cnt=$(printf "%04d" "${cnt}")
            # Set current app rule
            curl -s -u admin:netwitness http://127.0.0.1:50104/decoder/config/rules/network/$cnt?force-content-type=text/plain -d msg=set --data-urlencode value@$i 
        done
    else
        echo "No network rules to process..."
        sleep 1
    fi
} 
brokerContent () {
    # Variables
    thumb=$1

    # Tell them what we are doing
    echo "Backing up and pushing broker content..."
    sleep 2
    # Make folder to back up file
    if [ ! -e /etc/netwitness/ng/backups ]; then
        mkdir /etc/netwitness/ng/backups/
    fi
    # Back up file
    if [ -e /etc/netwitness/ng/index-broker-custom.xml ]; then
        cp -u /etc/netwitness/ng/index-broker-custom.xml /etc/netwitness/ng/backups
    fi
    # Sync index-concentrator-custom.xml
    find $thumb -type f -iname index-broker-custom.xml -print | xargs -I file cp -u file /etc/netwitness/ng/
}


#///////////////////////////// Main /////////////////////////////////////

echo "Preapring to load content from thumb drive"
# Call funtions with mount point to thumb drive
contentChk $1 
contentConfig $1
