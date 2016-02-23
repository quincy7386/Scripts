SA POC Configuration Utility version 1.0

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
the appliance or it could be run from a thumb drive. To invoke the 
utility run:

    # sh menu.sh

This script will present the user with a menu to choose which 
configuration action they would like to preform. menu.sh will
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

To deploy your own custom content you would need to create a zip
file called resource.bundle-custom.zip with the following directory
structure:

    APPRULE
	FEED
	PARSER

Capitalization is required. Store the appropriate files in the 
above folders.

If you want to deploy an index-concentrator-custom.xml or 
index-decoder-custom.xml, just place then on the root of the thumb drive.

LIMITATIONS:

Currently, only application rules, feeds and parsers are deployed
from the resource.bundle.

QUESTIONS/COMMENTS/BUGS:

Jon S. Nelson
jon.nelson@rsa.com
707-456-7386