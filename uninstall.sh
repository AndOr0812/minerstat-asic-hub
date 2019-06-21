#!/bin/sh
echo "--------- MINERSTAT ASIC HUB (UNINSTALL) -----------"

echo "Uninstall => Start"

# kill running process
screen -S minerstat -X quit
screen -S ms-run -X quit # kill running process
killall minerstat.sh
killall minerstat_antminer.sh
killall spond_beat.sh
killall inno_beat.sh
killall hyperbit_beat.sh
killall braiins_beat.sh
killall bitmain_beat.sh
killall baikal_beat.sh
echo "minerstat => Killed"


echo "Remove => Cronjobs"
# CGMINER CRON DELETE
if [ -d "/config" ]; then
    if [ -f "/config/cgminer.conf" ]; then
        if grep -q wipe "/config/network.conf"; then
            sed -i '$ d' /config/network.conf
        fi
        if grep -q minerstat "/config/network.conf"; then
            sed -i '$ d' /config/network.conf
        fi
    fi
fi
# BMMINER & SGMINER CRON DELETE
rm /etc/init.d/minerstat &> /dev/null

# MINERSTAT REMOVE
if [ -d "/config" ]; then
    if [ -f "/config/cgminer.conf" ]; then
        CONFIG_PATH="/config"
    fi
    if [ -f "/config/bmminer.conf" ]; then
        CONFIG_PATH="/config"
    fi
fi

if [ -d "/var/www/html/resources" ]; then
    CONFIG_PATH="/var/www/html/resources"
fi

############################
# Spondoolies
if [ -f "/etc/cgminer.conf" ]; then
		CONFIG_PATH="/etc"
fi

if [ -f "/opt/scripta/etc/miner.conf" ]; then
    CONFIG_PATH="/opt/scripta/etc"
fi

if grep -q InnoMiner "/etc/issue"; then
	if [ -d "/config" ]; then
		if [ -f "/config/cgminer.conf" ]; then
			CONFIG_PATH="/config"	
		fi
	fi
fi

if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
    CONFIG_PATH="/etc"
fi

if [ -d "/home/www/conf" ]; then
    CONFIG_PATH="/home/www/conf"
fi

if [ -d "/data/etc/config" ]; then
    CONFIG_PATH="/data_bak/etc/config"
fi

if [ -d "/usr/app" ]; then
    CONFIG_PATH="/usr/app"
fi

echo "Remove => /$CONFIG_PATH/minerstat/*"
rm -rf "$CONFIG_PATH/minerstat"

echo "Uninstall => Done"

sleep 2
nohup sync > /dev/null 2>&1 &
exit 0
