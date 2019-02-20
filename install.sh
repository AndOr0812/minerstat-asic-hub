#!/bin/sh
exec 2>/dev/null
mount -o remount,rw  / #remount filesystem

echo "--------- MINERSTAT ASIC HUB (INSTALL) -----------"

if [ "$1" != "" ]; then
    if [ "$1" != "null" ]; then
        echo "TOKEN: ok"
    else
        echo "No ACCESS_KEY DEFINED"
        exit 0
    fi
else
    echo "No ACCESS_KEY DEFINED"
    exit 0
fi

if [ "$2" != "" ]; then
    if [ "$2" != "null" ]; then
        echo "WORKER: ok"
    else
        echo "No WORKER_NAME DEFINED"
        exit 0
    fi
else
    echo "No WORKER_NAME DEFINED"
    exit 0
fi

############################
# FIX DAYUN
if [ -d "/var/www/html/resources" ]; then
	apt-get update
	apt-get install bash
	apt-get install screen curl --fix-missing
	cp /bin/sh /bin/sh2
	rm /bin/sh
	cp /bin/bash /bin/sh
	#wget https://busybox.net/downloads/binaries/1.21.1/busybox-armv7l # change this to GITHUB
fi

if [ -f "/etc/cgminer.conf" ]; then
	rm -rf /etc/minerstat
fi

if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
  # Screen and curl were removed
  # https://openwrt.org/packages/start
  opkg update
  opkg install screen
  opkg install curl
fi

#############################
# TESTING CURL
echo "-*-*-*-*-*-*-*-*-*-*-*-*"
rm error.log
curl 2> error.log

if grep -q libcurl.so.5 "error.log"; then
    echo "CURL PATCH APPLIED !"
    ln -s /usr/lib/libcurl-gnutls.so.4 /usr/lib/libcurl.so.5
else
    echo "CURL IS OK!"
fi


#############################
# TESTING CPU
#cat /proc/cpuinfo
rm /etc/systemd/system/multi-user.target.wants/minerstat.service

#############################
# TESTING NC
echo "-*-*-*-*-*-*-*-*-*-*-*-*"
rm error.log

sleep 1

nc 2> error.log

sleep 1

if grep -q found "error.log"; then
    echo "NC PATCH APPLIED !"
    # INSTALL NC
    	cd /bin
	curl -O https://busybox.net/downloads/binaries/1.21.1/busybox-armv7l --insecure # change this to GITHUB
	chmod 777 busybox-armv7l
	busybox-armv7l --install /bin
else
    echo "NC IS OK!"
fi

#############################
# DETECT-REMOVE INVALID CONFIGS
MINER="null"
TOKEN="null"
ASIC="null"

if [ -f "/etc/init.d/cgminer.sh" ]; then
    rm "/config/bmminer.conf"
fi

if [ -f "/etc/init.d/bmminer.sh" ]; then
    rm "/config/cgminer.conf"
fi

#############################
# DETECT FOLDER
if [ -d "/config" ]; then
    ASIC="antminer"
    CONFIG_PATH="/config"
    if [ -f "/config/cgminer.conf" ]; then
        MINER="cgminer"
        CONFIG_FILE="cgminer.conf"
        ASIC="antminer"
    fi
    if [ -f "/config/bmminer.conf" ]; then
        MINER="bmminer"
        CONFIG_FILE="bmminer.conf"
        ASIC="antminer"
    fi
fi

if [ -f "/config/bmminer.conf" ]; then
    MINER="bmminer"
    CONFIG_FILE="bmminer.conf"
    ASIC="antminer"
fi

if [ -d "/var/www/html/resources" ]; then
    MINER="cgminer"
    CONFIG_FILE="cgminer.config"
    CONFIG_PATH="/var/www/html/resources"
    ASIC="dayun"
fi

if [ -d "/home/www/conf" ]; then
    MINER="cgminer"
    CONFIG_FILE="cgminer.conf"
    CONFIG_PATH="/home/www/conf"
    ASIC="innosilicon"
fi

############################
# Spondoolies
if [ -f "/etc/cgminer.conf" ]; then
   		echo "Spondoolies FOUND"
		MINER="cgminer"
        	CONFIG_FILE="cgminer.conf"
        	ASIC="spondoolies"
		CONFIG_PATH="/etc"
fi

if [ -f "/opt/scripta/etc/miner.conf" ]; then
    CONFIG_FILE="miner.conf"
    MINER="sgminer"
    CONFIG_PATH="/opt/scripta/etc"
    ASIC="baikal"
fi

if grep -q InnoMiner "/etc/issue"; then
	if [ -d "/config" ]; then
		if [ -f "/config/cgminer.conf" ]; then
			MINER="cgminer"
        		CONFIG_FILE="cgminer.conf"
        		ASIC="innosilicon"
			CONFIG_PATH="/config"
		fi
	fi
fi

if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
    MINER="cgminer"
    CONFIG_FILE="cgminer.conf"
    ASIC="braiinsos"
    CONFIG_PATH="/etc"
    echo "BraiinsOS Detected"
fi

cd $CONFIG_PATH

#############################
# REMOVE PREV. Installation
screen -S minerstat -X quit # kill running process
screen -S ms-run -X quit # kill running process
screen -ls secure | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done

screen -wipe
rm -rf minerstat
rm minerstat.sh

mkdir minerstat
chmod 777 minerstat
cd $CONFIG_PATH/minerstat

if [ -f "/opt/scripta/etc/miner.conf" ]; then
	mkdir /opt/scripta/etc/minerstat
	chmod 777 /opt/scripta/etc/minerstat
	sleep 2
	echo "Trying to step in baikal minerstat folder"
	cd /opt/scripta/etc/minerstat
fi

MODEL=$(sed -n 2p /usr/bin/compile_time)

#############################
# DOWNLOAD
chmod 777 minerstat.sh
rm minerstat.sh

if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
	echo "Downloading generic script"
  	curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/minerstat.sh
else

	if [ "$ASIC" = "antminer"]; then
		echo "Downloading only antminer script"
		curl --insecure -H 'Cache-Control: no-cache' -s -o minerstat.sh https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/minerstat_antminer.sh
	else
		echo "Downloading generic script"
  		curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/minerstat.sh
	fi

fi

chmod 777 minerstat.sh

#############################
# SETTING UP USER

if [ $1 != "" ]; then
    if [ $2 != "" ]; then
        echo "---- USER -----"
        echo -n > minerstat.txt
        echo "TOKEN=$1" > minerstat.txt
        UPPER=$(echo "$2" | awk '{print toupper($0)}')
        echo "WORKER=$UPPER" >> minerstat.txt
        cat minerstat.txt # Echo after finish
	if [ -d "/config" ]; then
		sed -i '/hostname/d' /config/network.conf
		echo "hostname=$UPPER" >> /config/network.conf
	fi
	hostname $UPPER
    else
        echo "EXIT => Worker is not defined"
        exit 0
    fi
else
    echo "EXIT => Token is not defined"
    exit 0
fi

#############################
# SETTING UP CRON
rm runmeonboot
rm hbeat.sh
rm spond_start.sh
rm spond_beat.sh
rm baikal_beat.sh
rm inno_beat.sh
rm bitmain_beat.sh
rm braiins_beat.sh

curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/runmeonboot
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/hbeat.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/spond_start.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/update.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/spond_beat.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/baikal_beat.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/inno_beat.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/bitmain_beat.sh
curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/braiins_beat.sh


chmod 777 runmeonboot
chmod 777 hbeat.sh
chmod 777 spond_start.sh
chmod 777 spond_beat.sh
chmod 777 baikal_beat.sh
chmod 777 inno_beat.sh
chmod 777 bitmain_beat.sh
chmod 777 braiins_beat.sh
#ln -s runmeonboot /etc/rc.d/

dir=$(pwd)

if [ -f "/config/network.conf" ]; then
    ## WIPE
    if grep -q wipe "/config/network.conf"; then
        echo "no wipe needed"
    else
        echo "screen -wipe; sleep 10" >> /config/network.conf
    fi
    ## CRON
    if grep -q minerstat "/config/network.conf"; then
        echo "cron installed"
    else
        echo "cron not installed, installing"
        echo "screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh" >> /config/network.conf
        #echo "screen -A -m -d -S minerstat-secure sh /config/minerstat/bitmain_beat.sh" >> /config/network.conf
    fi
    if grep -q secure "/config/network.conf"; then
        echo "cron installed"
    else
        echo "cron not installed, installing"
        echo "screen -A -m -d -S secure sh /config/minerstat/bitmain_beat.sh" >> /config/network.conf
    fi
fi

if grep -q InnoMiner "/etc/issue"; then
	#echo "Cron not implemented yet"

	if [ -f "/etc/systemd/system/multi-user.target.wants/cgminer.service" ]; then
	#	if grep -q minerstat "/etc/profile"; then
    #    	echo "cron installed"
    #	else
    #		echo "cron not installed, installing"
    #    	echo "screen -wipe; sleep 10" >> /etc/profile
    #    	echo "screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh" >> /etc/profile
    #	fi
    	TESTCRON=$(systemctl is-enabled minerstat)
    	if [ -f "/etc/systemd/system/multi-user.target.wants/minerstat.service" ]; then
    		echo "cron exist for innosilicon"
    	else
    		echo "non exist for innosilicon"
    		echo "Installing cron as a system Service"

    		# INNO-CRON
    		# find / -name cgminer.service
			#/etc/systemd/system/multi-user.target.wants/cgminer.service
			#/usr/lib/systemd/system/cgminer.service
			cd /usr/lib/systemd/system/
			curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/system/lib/minerstat.service
			chmod 777 minerstat.service
			cd /etc/systemd/system/multi-user.target.wants/
			curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/system/lib/minerstat.service
			chmod 777 minerstat.service
			#systemctl enable minerstat
			echo "Cron enabled"

			# safety cron
			if [ -f "/etc/systemd/system/multi-user.target.wants/cgminer.service" ]; then
				if grep -q minerstat "/etc/systemd/system/multi-user.target.wants/cgminer.service"; then
        				echo "safety cron here"
    		else
        				echo "need to install safety cron"

					cd /usr/lib/systemd/system/
					sed -i '/PrivateTmp=no/a ExecStartPre=/bin/sh -c "screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh"' cgminer.service
					sed -i '/PrivateTmp=no/a ExecStartPre=/bin/sh -c "screen -wipe; sleep 5;"' cgminer.service
					sed -i '/PrivateTmp=no/a ExecStartPre=/bin/sh -c "mount -o remount,rw /"' cgminer.service
					rm /etc/systemd/system/multi-user.target.wants/cgminer.service
					systemctl enable cgminer
					systemctl start cgminer

    		fi
			fi

      if grep -q beat "/etc/systemd/system/multi-user.target.wants/cgminer.service"; then
            echo "watchdog is here"
      else
            echo "installing watchdog"
            cd /usr/lib/systemd/system/
            sed -i '/PrivateTmp=no/a ExecStartPre=/bin/sh -c "screen -A -m -d -S watchdog sh /config/minerstat/inno_beat.sh"' cgminer.service
            rm /etc/systemd/system/multi-user.target.wants/cgminer.service
  					systemctl enable cgminer
  					systemctl start cgminer
      fi

			#systemctl start minerstat
			#screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh
			nohup sync && sleep 200 && mount -o remount,rw  / &

    	fi
	fi
fi

# DAYUN CRONTAB
if [ -d "/var/www/html/resources" ]; then
	crontab -l > mycron
	if grep -q minerstat "mycron"; then
    		echo "CRON IS OK!"
	else
		echo "CRON APPLIED !"
    		echo "* * * * * sh /var/www/html/resources/minerstat/hbeat.sh" >> mycron
		crontab mycron
	fi
	rm mycron
fi

############################
# Spondoolies CRONTAB
if [ -f "/etc/cgminer.conf" ]; then
		if grep -q minerstat "/etc/init.d/S99startup"; then
    			echo "CRON IS OK!"
		else
			echo "CRON APPLIED !"
			#echo "/bin/sh /etc/minerstat/spond_start.sh" >> /usr/local/bin/watchdog.sh
			#sed -i '/start)/a nohup /bin/sh /etc/minerstat/minerstat.sh &' /etc/init.d/S01logging
			#echo "rm /etc/minerstat/log.txt && echo 'starting minerstat..' >> /etc/minerstat/log.txt" >> /etc/init.d/S99startup
			echo "sleep 60 && nohup /bin/sh /etc/minerstat/minerstat.sh &" >> /etc/init.d/S99startup
			echo "* * * * * /bin/sh /etc/minerstat/spond_beat.sh" >> /etc/cron.d/crontabs/root
			echo "* * * * * /bin/sh /etc/minerstat/spond_beat.sh" >> /etc/cron.d/crontabs.4560
		fi
fi

if [ -f "/opt/scripta/etc/miner.conf" ]; then
	if grep -q minerstat "/etc/cron.d/scripta"; then
    			echo "CRON IS OK!"
		else
			echo "CRON APPLIED !"
			echo "* * * * * root /bin/sh /opt/scripta/etc/minerstat/baikal_beat.sh" >> /etc/cron.d/scripta
		fi
fi

############################
# Braiins CRONTAB

rm /etc/crontabs/root # temp solution to solve bad installs

if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
  if grep -q beat "/etc/crontabs/root"; then
    echo "CRON IS OK!"
  else
    echo "INSTALLING CRON FOR BRAIINSOS"
    # /etc/crontabs
    # -> cron.update
    # -> root

    echo "" > /etc/crontabs/root
    echo "* * * * * /bin/sh /etc/minerstat/braiins_beat.sh" >> /etc/crontabs/root
    service cron restart
  fi
fi


#echo -n > /etc/init.d/minerstat
#chmod 777 /etc/init.d/minerstat
#echo "#!/bin/sh" >> /etc/init.d/minerstat
#echo "sh $dir/runmeonboot" >> /etc/init.d/minerstat
#chmod ugo+x /etc/init.d/minerstat
#update-rc.d minerstat defaults

#if [ $MINER != "cgminer" ]; then
#	echo -n >  /etc/rcS.d/S71minerstat
#	echo "#!/bin/sh" >> /etc/rcS.d/S71minerstat
#	echo "sh $dir/runmeonboot" >> /etc/rcS.d/S71minerstat
#fi


########################
# POST Config
cd $CONFIG_PATH/minerstat

TOKEN=$1
WORKER=$2
CURRCONF=$(cat "$CONFIG_PATH/$CONFIG_FILE")

echo "$CURRCONF"

#if [ "$3" != "noupload" ]; then
    POSTREQUEST=$(curl -s --insecure -H 'Cache-Control: no-cache' --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "node=$CURRCONF" https://api.minerstat.com/v2/set_asic_config.php)
    echo "CONFIG POST => $POSTREQUEST"
#fi



#############################
# START THE SCRIPT

echo "Installation => DONE"

if [ -f "/etc/cgminer.conf" ]; then
	if grep -q InnoMiner "/etc/issue"; then
		echo "Notice => You can check the process running with: screen -list"
		screen -A -m -d -S minerstat ./minerstat.sh $4
		screen -list
		nohup sync > /dev/null 2>&1 &
    screen -A -m -d -S watchdog sh /config/minerstat/inno_beat.sh
	else
    if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
      /bin/sh /etc/minerstat/braiins_beat.sh # Start braiinsOS
      screen -list
    else
      echo "Notice => You can check the process running with: jobs -l"
      nohup /bin/sh /etc/minerstat/minerstat.sh &
      jobs -l
    fi
	fi
else
	echo "Notice => You can check the process running with: screen -list"
	screen -A -m -d -S minerstat ./minerstat.sh $4
  screen -A -m -d -S secure sh /config/minerstat/bitmain_beat.sh
	screen -list
	nohup sync > /dev/null 2>&1 &
fi

# DEBUG
sleep 2
echo "Extra: $4"

exit 0
