#!/bin/sh

# CHECK FOR DEPENDENCIES
ERROR="0"

if ! which jq > /dev/null
then
	ERROR="1"
fi

if ! which sshpass > /dev/null
then
	ERROR="1"
fi

if ! which curl > /dev/null
then
	ERROR="1"
fi

if [ "$ERROR" != "0" ]; then
	echo "Need to install dependencies: "
	echo "The install script will ask your root password. "
	echo "sudo apt-get -y install jq sshpass curl"
	sudo apt-get -y install jq sshpass curl
fi

# ASK USER INPUT
echo "Please enter your ACCESS KEY"
read ACCESS_KEY
echo ""

echo "Please enter your group/location [Default: asic] [Enter to skip]"
read GROUP
echo ""

echo "Please enter your netmask [Default: 255.255.255.0] [Enter to skip]"
read NETMASK
echo ""

echo "Please enter your gateway"
read GATEWAY
echo ""

echo "Please enter your DNS SERVER [Default: 1.1.1.1] [Enter to skip]"
read DNS
echo ""

if [ -z "$ACCESS_KEY" -a "$ACCESS_KEY" != " " ]; then
	echo "ERROR: No accesskey provided"
	exit 0
fi

if [ -z "$GROUP" -a "$GROUP" != " " ]; then
	GROUP="asic"
	echo "WARNING: No group/location provided."
	echo "WARNING: The software will be installed on all of your ASIC workers."
fi

if [ -z "$GATEWAY" -a "$GATEWAY" != " " ]; then
	echo "ERROR: No gateway provided"
	exit 0
fi

if [ -z "$NETMASK" -a "$NETMASK" != " " ]; then
	NETMASK="255.255.255.0"
	echo "NOTICE: No netmask provided, Using: 255.255.255.0"
fi

if [ -z "$DNS" -a "$DNS" != " " ]; then
	DNS="1.1.1.1"
	echo "NOTICE: No DNS SERVER provided, Using: 1.1.1.1"
fi

# PING API
id=0
row=$(curl -s "https://api.minerstat.com/v2/stats/$ACCESS_KEY?filter=asic&group=$GROUP")

# CHECK FOR ERROR FIRST
ERROR=$(echo $row | jq -r ".error")
if [ ! -z "$ERROR" -a "$ERROR" != "null" ]; then
	echo "----------------------------------------"
	echo $ERROR
	echo "----------------------------------------"
	exit 1
fi

# CALCULATE OBJECTS
IP=$(echo $row | jq -r ".[] | .info.os.localip")
COUNT=$(echo $IP | wc -w)

if [ "$COUNT" -gt "0" ]; then
	ARRAY=$(echo $row | jq 'to_entries|map([.key] + .value.a|map(tostring)|join(" "))')
	#echo "DEBUG OUTPUT, IP LIST:"
	#echo $ARRAY

	for i in $(echo $ARRAY | jq  -r '.[]')
	do
    	echo ""
   		IP=$(echo $row | jq -r " .[\"$i\"].info.os.localip")
   		LOGIN=$(echo $row | jq -r " .[\"$i\"].info.auth.user")
   		PASS=$(echo $row | jq -r " .[\"$i\"].info.auth.pass")

   		echo "----------------------------------------"
   		echo "$IP: Logging in with $LOGIN / $PASS [$i]"


		# SSH TOUCH

		INSTALL="echo 'RESPONSE: Setting up networking..'; echo 'ipaddress=$IP' >> /config/network.conf; echo 'netmask=$NETMASK' >> /config/network.conf; echo 'gateway=$GATEWAY' >> /config/network.conf; echo 'dnsservers=$DNS' >> /config/network.conf;"
		INSTALL="cat /config/network.conf | grep 'ipaddress' && echo 'RESPONSE: Already configured' || ($INSTALL)"
		echo "$IP: CONFIGURING"


		sshpass -p$PASS ssh $LOGIN@$IP -p 22 -oStrictHostKeyChecking=no -oConnectTimeout=12 "$INSTALL"
		if [ $? -ne 0 ]; then
			echo "$IP: ERROR"
		else
			echo "$IP: OK"
		fi

		echo "----------------------------------------"

	done

else
	echo "You have no workers on $ACCESS_KEY account.";
	echo "Common issue: Wrong Group/Location were used.";
fi

# END
