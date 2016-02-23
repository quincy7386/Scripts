SA POC Configuration Utility version 1.0.14

This utility is a set of scripts that was designed to aid in the 
configuration process during a SA POC. Currently, the utility
will perform the following configuration steps:

    * Networking (IP, DNS, NTP, Hostname, Timezone)
    * Yum configuration
    * Content distribution (limited)
    * Decoder tuning (basic)

The user is prompted for the requisite information to configure the
areas above, so they no longer have to remember commands to run or
files to edit.

USAGE:

To start using the script copy the contents of the configPOC.7z to 
the appliance or it could be run from a thumb drive. Set the permissions
on all the scripts:

    # cd <script dir> 
    # chmod 755 *.sh ./bin/

To invoke the utility run:

    # ./configPOC.sh
	
This script will present the user with a menu to choose which 
configuration action they would like to preform. configPOC.sh will
then run the appropriate scripts from the bin/ directory. If an 
error occurs while running a script, the whole utility aborts.

REQUIREMENTS:

To deploy content the script requires that a resource.bundle<timestamp>.zip
file be present on the appliance. This file can be generated in 
the SA thin client: Live -> Search. Then select the application 
rules, feeds, and parsers to deploy. Then choose Package -> Create. 
It can be on a thumb drive or on the local file system.

There can only be one resource.bundle on the thumb drive or 
file system at a time.

CUSTOM CONTENT:

To deploy your own custom content you would need to create a zip and
place it on the root of the thumb drive.

If you want to deploy an index-concentrator-custom.xml or 
index-decoder-custom.xml, just place them in the zipfile or on the 
root of the thumb drive.

LIMITATIONS:

* Currently, rules, reports, and charts are not automatically deployed 
  from the zip file.
* Cannot configure ESA due to the lack of NwConsole on the appliance
 
RELEASE NOTES:

1.0.14
* Fixed several of the tweaks in the decoder tuning script as suggested by Rui Ataide
1.0.13
* A **lot** of bug fixes
* Fixed content deployment

1.0.6
* Fixed erroneous comparison in DNS configuration

1.0.5
* Fixed static interface in tweekDecoder.sh
* Renamed menu.sh to configPOC.sh
* Added pause to review decoder tweaks when done
* Fixed logic for editing /etc/resolv.conf
* Fixed logic to determine when to quit time zone configuration

1.0.4
* Fixed NTP seg fault issue

1.0.3
* Fixed bug where script was stuck in a loop for network configuration
* Setting NTP may cause a seg fault, but this is do to the NwConsole script

1.0.2
* Durring network config show user current value
* Fixed missing hostname in /etc/hosts
* Fixed dhcp configuration
* Fixed parsing of multiline nwr files
* Added logic to test if NwConsole fails, but it doesn't have proper exit codes.
  When NwConsole is fixed this should work.
* Updated README.txt to reflect changes and minor edits.

1.0.1
* Added logic to process network and correlation rules via REST API.
* Added messaging to better inform user of what is currently processing.
* Updated README.txt to reflect changes and minor edits.

QUESTIONS/COMMENTS/BUGS:

Jon S. Nelson
jon.nelson@rsa.com
707-456-7386
