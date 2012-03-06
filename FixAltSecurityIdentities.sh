#!/bin/sh
# Arek Dreyer
# arek@arekdreyer.com
# Mon Mar  5 20:38:21 CST 2012
#
# Apologies for the bad and mixed shell scripting styles.
#
# If users have Kerberos:untitled_1@REALMNAME in their AltSecurityIdentites
# attribute, replace "untitled_1" with their username.
#
# Run this on an OD master (or in Lion, a replica)
# Search for users in the /LDAPv3/127.0.0.1 path
#
# This script assumes that users under uid 1001 are system users; do not
# create any home folder for those users.
#
# UPDATE THESE VARIABLES FOR YOUR ENVIROMNEMT
#
# Remember that in Lion, it's best to not have the same directory
# administrator name on multiple servers, so for sever17, I used
# diradmin17 as the shortname. 
#
# DIRADMINPW should be the directory administrator's password 
#
DIRADMIN="diradmin17"
DIRADMINPW="diradmin17pw"
NODE="/LDAPv3/127.0.0.1"
REALM="SAMPLE.AREKDREYER.COM"
#
#
awk="/usr/bin/awk"
dscl="/usr/bin/dscl"
MAXUID=1001
BADATTR="Kerberos:untitled_1@${REALM}"
#
#
for USERID in $($dscl ${NODE} -list Users); do 
        UNIQUEID=$( $dscl -plist ${NODE} -read /Users/${USERID} UniqueID | \
		$awk -F '[<|>]' '/string/ {print $3}')
        if [ ${UNIQUEID} -gt ${MAXUID} ]; then
		ALTSECID=$( $dscl -plist ${NODE} \
			-read /Users/${USERID} AltSecurityIdentities | \
			$awk -F '[<|>]' '/string/ {print $3}')
		if [ :${ALTSECID} = :${BADATTR} ]; then
			echo "Updating record for ${USERID}"
			NEWATTR="Kerberos:${USERID}@${REALM}"
			$dscl -u ${DIRADMIN} -P ${DIRADMINPW} \
			${NODE} -change /Users/${USERID} AltSecurityIdentities \
			${BADATTR} ${NEWATTR}
		fi
	else
		echo "Skipping system user ${USERID} ${UNIQUEID}"
	fi
done
