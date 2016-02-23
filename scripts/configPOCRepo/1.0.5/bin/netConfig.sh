#!/bin/bash
#
# This script configures a new SA appliance with IP, Hostname, DNS, and NTP.
# The user is shown the current configuration and prompted to change it if
# needed.
# Written by Jon Nelson, jon.nelson@rsa.com, 11/7/2013



#///////////////////////////// Functions /////////////////////////////////////

# This function configures networking 
function network () {
    while [ 1 -eq 1 ]; do
        #Clear the screen
        clear
		# Find first interface
		iface=$(ifconfig | head -1 | awk 'BEGIN { RS = "" } !/lo/ { print $1 }')
		#Display current settings
		echo -e "\n\nHere is your current networking configuration:\n\n"
		cat /etc/sysconfig/network-scripts/ifcfg-$iface
		# Prompt for changes
        echo -ne "\nDo you want to make changes to networking (y/n)? "
        read answer
        # Made their choice
        case "$answer" in
            y|Y)
				# Show current config
				echo "Network configuration:"
				echo -e "Current setting is in square brackets. Hit <Enter> to accept, or enter a new value.\n\n"
				# Find first interface
				iface=$(ifconfig | head -1 | awk 'BEGIN { RS = "" } !/lo/ { print $1 }')
				# Source the correct file
				. /etc/sysconfig/network-scripts/ifcfg-$iface
				# Promt the user for changes
				echo -n "Mode (static/dhcp) [$BOOTPROTO]: "
				read mode
				# If they didn't provide a new value, use the old one
				if [[ "$BOOTPROTO" = "none" || "$mode" = "static" ]]; then
					mode=static
				else
					# Set DHCP and we are done
					NwConsole -c login 127.0.0.1:50006 admin netwitness -c appliance setNet mode=dhcp
					if [ $? -eq 0 ]; then
						echo -ne "\nNetwork configuration complete. Hit <Enter> to continue..."
						read
						return
					else
						echo "Error configuring network. Aborting..."
						exit 1
					fi

				fi
				echo -n "IP Address [$IPADDR]: "
				read IP
				# If they didn't provide a new value, use the old one
				if [ -z "$IP" ]; then
					IP=$IPADDR
				fi
				echo -n "Netmask [$NETMASK]: "
				read mask
				# If they didn't provide a new value, use the old one
				if [ -z "$mask" ]; then
					mask=$NETMASK
				fi
				echo -n "Gateway [$GATEWAY]: "
				read gw
				# If they didn't provide a new value, use the old one
				if [ -z "$gw" ]; then
					gw=$GATEWAY
				fi
				NwConsole -c login 127.0.0.1:50006 admin netwitness -c appliance setNet mode=$mode address=$IP netmask=$mask gateway=$gw
				if [ $? -eq 0 ]; then
					echo -ne "\nNetwork configuration complete. Hit <Enter> to continue..."
					read
					return
				else
					echo "Error configuring network. Aborting..."
					exit 1
				fi 
			;;
		    n|N)
				echo "No changes made."
				sleep 1
				return
			;;
		esac
    done
}

# This function confiures DNS
function dns () {
    while [ 1 -eq 1 ]; do
        # Clear the screen
        clear
        # Show current config
        echo -e "\n\nHere is your current DNS configuration:\n\n"
        cat "/etc/resolv.conf"
        # Prompt for changes
        echo -ne "\nDo you want to make changes (y/n)? "
        read answer
        # Made their choice
        case "$answer" in
            y|Y)
                echo -n "Client's Domain: "
                read domain
                echo -n "DNS Server1: "
                read dns1
                echo -n "DNS Server2 (or enter 0 for none): "
                read dns2
                # Edit the settings
                sed -i.bak -e "s/\(^search\ \)\(.*$\)/\1$domain/" /etc/resolv.conf
                sed -i.bak -e "/$dns1/ s/\(^nameserver\ \)\(.*$\)/\1$dns1/" /etc/resolv.conf
                # Check to see if they had more than one DNS entry
                if [ $dns2 -ne 0 ]; then
                    # Push it on the end
                    echo "nameserver $dns2" >> /etc/resolv.conf
                fi
                if [ $? -eq 0 ]; then
                    echo -ne "\nDNS configuration complete. Hit <Enter> to continue..."
                    read
                else
                    "Error configuring DNS. Aborting..."
                    exit 1
                fi 
            ;;
            n|N)
                echo -e "\nNo changes made."
                sleep 1
                return
            ;;
        esac
    done
}

# This function confiures the hostname
function hostName () {
    while [ 1 -eq 1 ]; do
        # Clear the screen
        clear
        # Show the current config
        echo -e "\n\nHere is your current hostname configuration:\n\n"
        cat "/etc/sysconfig/network" | grep HOSTNAME
        # Prompt the user
        echo -ne "\nDo you want to make changes (y/n)? "
        read answer
        # They made their choice
        case "$answer" in
            y|Y)
                echo -n "Hostname: "
                read hostname
                NwConsole -c login 127.0.0.1:50006 admin netwitness -c appliance hostname name=$hostname
                sed -i.bak -e "s/\(^127.0.0.1.*\)/\1\ $hostname/" /etc/hosts
                if [ $? -eq 0 ]; then
                    echo -ne "\nHostname configuration complete. Hit <Enter> to continue..."
                    read
                    return
                else
                    "Error configuring hostname. Aborting..."
                    exit 1
                fi 
            ;;
            n|N)
                echo -e "\nNo changes made."
                sleep 1
                return
            ;;
        esac
    done
}

# This function sets the time server
function timeSrv () {
    while [ 1 -eq 1 ]; do
        # Clear the screen
        clear
        # Show the current config
        echo -e "\n\nHere is your current time server configuration:\n\n"
        cat "/etc/ntp.conf" | grep "^server\ "
        # Prompt the user
        echo -ne "\nDo you want to make changes (y/n)? "
        read answer
        # Made their choice
        case "$answer" in
            y|Y)
                echo -n "NTP Server: "
                read server
                NwConsole -c login 127.0.0.1:50006 admin netwitness -c appliance setNTP source=$server
                if [ $? -eq 0 ]; then
                    echo -ne "\nTime server configuration complete. Hit <Enter> to continue..."
                    read
                else
                    "Error configuring time server. Aborting..."
                    exit 1
                fi 
            ;;
            n|N)
                echo -e "\nNo changes made."
                sleep 1
                return
            ;;
        esac
    done
}

# This function sets the timezone
function timeZone () {
    while [ 1 -eq 1 ]; do
        # Clears the screen
        clear
        # Shows the current config
        echo -ne "\n\nHere is your current timezone configuration: "
        ls -l /etc/localtime | awk 'BEGIN { FS = "/" } { print $NF }'
        # Prompts the user
        echo -ne "\nDo you want to make changes (y/n)? "
        read answer
        # Made their choice
        case "$answer" in
            y|Y)
                # Just here to make the while loop infinite
                stop=0
                while [ $stop -ne 99 ]; do
                    # Prompt the user
                    echo -n "Time zone (if entering two words separate by _ like 'New_York') : "
                    read zone
                    cnt=1
                    # Display possible choices
                    for i in $(find /usr/share/zoneinfo -type f -iregex ".*$zone$"); do 
                        zones[$cnt]=$i
                        echo "$cnt: $i"
                        ((cnt++))
                    done
                    # Show other options
                    echo "98: Try another time zone"
                    echo "99: Quit"
                    echo -n "Choose your timezone by number: "
                    read choice
                    # They made their choice
                    case "$choice" in
                        98)
                        # Try again
                        ;;
 
                        99)
                            # Quit
                            return
                        ;;
                     
                        *)
                            # Make the change
                            ln -sf ${zones[$choice]} /etc/localtime
                            echo -ne "\nTime zone configuration complete.\n"
							# Show other options
							echo "98: Try another time zone"
							echo "99: Quit"
                            read stop
                       ;;
                    esac
                done
            ;;
            n|N)
                echo -e "\nNo changes made."
                sleep 1
                return
            ;;
        esac
   done 
}

#///////////////////////////// Main /////////////////////////////////////

network
dns
hostName
timeSrv
timeZone

