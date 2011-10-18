#!/bin/sh
#
# 2011-09-15 -- jontow@zenbsd.net
#
# Check DHCP pool size by cheating and using a pre-generated
# listing from the "dhcpstats" script HTML output.
#

DHCPSTAT="http://example.com/dhcpstats/stat.html"

TOTPERCENT=`wget -q -O - ${DHCPSTAT} | grep "TOTAL" | awk -F\% '{print $1}' | awk -F\> '{print $NF}'`

if [ $TOTPERCENT -ge 90 ]; then
	# NAGIOS CRITICAL
	echo "${TOTPERCENT} ge 90"
	exit 2
elif [ $TOTPERCENT -ge 75 ]; then
	# NAGIOS WARNING
	echo "${TOTPERCENT} ge 75"
	exit 1
fi

# NAGIOS OK
echo "${TOTPERCENT} lt 50"
exit 0
