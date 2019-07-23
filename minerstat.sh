#!/bin/sh
#exec 2>/dev/null

sleep 1

screen -wipe

sleep 1

# Fix inno crontab
if grep -q InnoMiner "/etc/issue"; then
	if [ -d "/config" ]; then
		if [ -f "/config/cgminer.conf" ]; then
		        mkdir -p /var/spool/cron/crontabs 
    			echo "* * * * * /bin/sh /config/minerstat/inno_beat.sh" > /var/spool/cron/crontabs/root
    			start-stop-daemon -S -q -p /var/run/crond.pid --exec /usr/sbin/crond -- -l 9 			
		fi
	fi
fi

# FIX DAYUN crontab
if [ -d "/var/www/html/resources" ]; then
	mkdir -p /var/spool/cron/crontabs 
    	echo "* * * * * /bin/sh /var/www/html/resources/minerstat/hbeat.sh" > /var/spool/cron/crontabs/root
    	start-stop-daemon -S -q -p /var/run/crond.pid --exec /usr/sbin/crond -- -l 9 
fi

if ! screen -list | grep -q "ms-run" || [ "$1" = "forcestart" ]; then

    echo "--------- MINERSTAT ASIC HUB -----------"

    if ! screen -list | grep -q "ms-run"; then
    	# Fake Process, Boot & Double instance protection
    	screen -A -m -d -S ms-run sleep 3h
    fi

    sleep 10

    echo "-------- WAITING FOR CONNECTION -----------------"

    while ! ping minerstat.com -w 1 | grep "0%"; do
        sleep 1
    done

    # Remount filesystem
    mount -o remount,rw  / #remount filesystem

    #############################
    # TESTING NC
    echo "-*-*-*-*-*-*-*-*-*-*-*-*"
    rm error.log

    sleep 1

    nc 2> error.log

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

    rm error.log

    sleep 1

    cat minerstat.txt 2> error.log

    #############################
    # GLOBAL VARIBLES

    TOKEN="null"
    WORKER="null"
    MODEL="null"

    ASIC="null"
    MINER="null"
    MAINT="0"

    # SYNC
    FOUND="null"
    TCMD="null"
    RESPONSE="null"
    POSTDATA="null"

    # CONFIG
    CONFIG_PATH="/tmp"
    CONFIG_FILE="null"
    SYNC_ROUND=0
    SYNC_MAX=45

    #############################
    # TESTING CURL
    rm error.log

    sleep 1


    curl 2> error.log

    if grep -q libcurl.so.5 "error.log"; then
        echo "CURL PATCH APPLIED !"
        ln -s /usr/lib/libcurl-gnutls.so.4 /usr/lib/libcurl.so.5
    else
        echo "CURL IS OK!"
    fi

    #############################
    # CORE FUNCTIONS

    # 1) ASSIGN JOBS FOR DIFFERENT ASIC TYPES
    check() {
        # RESET TO NULL/TIMEOUT ON EVERY SYNC
        RESPONSE="timeout"
        POSTDATA="null"
        case $ASIC in
            antminer)
                fetch
                ;;
            baikal)
                fetch
                break
                ;;
            dayun)
                fetch
                break
                ;;
	    innosilicon)
                fetch
                break
                ;;
	    spondoolies)
                fetch
                break
                ;;
            braiinsos)
                fetch
                break
                ;;
	    whatsminer)
	    	fetch
		break
		;;
	    hyperbit)
	    	fetch
		break
		;;
            null)
                #echo "INFO => Detecting ASIC Type"
                detect
                ;;
            err)
                echo "EXIT => CODE (0)"
                exit 0
                ;;
        esac
    }

    # 2 DETECT ASIC TYPE
    detect() {
        # POSSIBLE NEED NEW METHOD OR MORE ADVANCED Detecting
        # TEMPORARY WILL BE GOOD

  if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
      echo "Braiins found"
      MINER="cgminer"
      CONFIG_FILE="cgminer.conf"
      ASIC="braiinsos"
      CONFIG_PATH="/etc"
      FOUND="Y"
      check
  else
    # Spondoolies
    if [ -f "/etc/cgminer.conf" ]; then
      echo "FOUND SPONDOOLIES"
      MINER="cgminer"
            CONFIG_FILE="cgminer.conf"
            ASIC="spondoolies"
      CONFIG_PATH="/etc"
      FOUND="Y"
      # CHECK PROTECTOR HEALTH
      CHECKHEALTH=$(ps | grep -c spond_beat.sh)
      if [ "$CHECKHEALTH" != "1" ]
      then
        echo ""
      else
        nohup /bin/sh /etc/minerstat/spond_beat.sh &
      fi
                check
    fi
  fi

	
	# DAYUN
        if [ -d "/var/www/html/resources" ]; then
            ASIC="dayun"
            MINER="sgminer"
            CONFIG_PATH="/var/www/html/resources"
            FOUND="Y"
            check
        fi
	
	 if [ -d "/data/etc/config" ]; then
            MINER="cgminer"
	    CONFIG_FILE="pools"
	    CONFIG_PATH="/data_bak/etc/config"
	    ASIC="whatsminer"
            FOUND="Y"
            check
        fi
		
	# Inno
	if grep -q InnoMiner "/etc/issue"; then
		if [ -d "/config" ]; then
			if [ -f "/etc/cgminer.conf" ]; then
			MINER="cgminer"
        		CONFIG_FILE="cgminer.conf"
        		ASIC="innosilicon"
			CONFIG_PATH="/etc"
			check
			fi
		fi
	fi

	# BAIKAL
        if [ -d "/opt/scripta/etc" ]; then
            ASIC="baikal"
            MINER="sgminer"
            CONFIG_PATH="/opt/scripta/etc"
	    CONFIG_FILE="miner.conf"
            FOUND="Y"
            check
        fi
        # BRAIINS OS
	
	 # INNOSILICON
        if [ -d "/home/www/conf" ]; then
            ASIC="innosilicon"
            MINER="cgminer"
            CONFIG_PATH="/home/www/conf"
	    CONFIG_FILE="miner.conf"
            FOUND="Y"
            check
        fi

	if [ -d "/usr/app" ]; then
   	    MINER="cpuminer"
    	    CONFIG_FILE="conf.default"
    	    CONFIG_PATH="/usr/app"
    	    ASIC="hyperbit"
	    FOUND="Y"
            check
	fi

        # MINER
        if [ $TOKEN = "null" ]; then
            #MODEL=$(sed -n 2p /usr/bin/compile_time)
            TOKEN=$(cat "$CONFIG_PATH/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            WORKER=$(cat "$CONFIG_PATH/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
        fi

        if [ $FOUND = "null" ]; then
            FOUND="err"
            echo "ERROR => This machine is not supported."
            echo "ERROR => Try to use ASIC Node instead."
            echo "EXIT => CODE (0)"
            exit 0
        fi

    }

    # 3) DETECT IS OK, GET DATA FROM TCP
    fetch() {

	if [ -f "/etc/cgminer.conf" ]; then
		if grep -q InnoMiner "/etc/issue"; then
			echo ""
		else
      if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
        echo ""
      else
			CHECKHEALTH=$(ps | grep -c spond_beat)
			if [ "$CHECKHEALTH" != "1" ]
    			then
				echo ""
			else
				nohup /bin/sh /etc/minerstat/spond_beat.sh &
			fi
		fi
  fi
	fi

        #echo "Detected => $ASIC"
            QUERY=$(echo '{"command": "stats+summary+pools+devs"}' | nc 127.0.0.1 4028)
            RESPONSE="""$QUERY "
	    if [ "$RESPONSE" != "timeout" ]; then
	    	post
	    else
		sleep 3
	    	QUERY=$(echo '{"command": "stats+summary+pools+devs"}' | nc 127.0.0.1 4028)
            	RESPONSE="""$QUERY "
		post
	    fi
    }

    # 4) SEND DATA TO THE SERVER
    post() {
        #echo "{\"token\":\"$TOKEN\",\"worker\":\"$WORKER\",\"data\":\"$RESPONSE\"}"
	LOCALIP=$(/sbin/ifconfig eth0 | grep Mask | sed 's/^.*addr/addr/' | cut -f1 -d" " | sed 's/[^0-9.]*//g')
	LOCALIP="""$LOCALIP"
	if [ -d "/var/www/html/resources" ]; then
		MODEL="DAYUN"
		TOKEN=$(cat "/var/www/html/resources/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            	WORKER=$(cat "/var/www/html/resources/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_FILE="cgminer.config"
	fi
	if [ -d "/usr/app" ]; then
   	    MODEL="HYPERBIT"
    	    CONFIG_FILE="conf.default"
    	    CONFIG_PATH="/usr/app"
    	    TOKEN=$(cat "/usr/app/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            WORKER=$(cat "/usr/app/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
	fi
	if grep -q InnoMiner "/etc/issue"; then
		MODEL="INNOSILICON"
		TOKEN=$(cat "/config/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            	WORKER=$(cat "/config/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_PATH="/etc"
		CONFIG_FILE="cgminer.conf"
	else
		if [ -f "/etc/cgminer.conf" ]; then
		MODEL="SPONDOOLIES"
		TOKEN=$(cat "/etc/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            	WORKER=$(cat "/etc/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_PATH="/etc"
		CONFIG_FILE="cgminer.conf"
		fi
		if [ -f "/config/cgminer.conf" ]; then
		MODEL="ANTMINER"
		TOKEN=$(cat "/config/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            	WORKER=$(cat "/config/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_PATH="/config"
		CONFIG_FILE="cgminer.conf"
		fi
		if [ -f "/config/bmminer.conf" ]; then
		MODEL="ANTMINER"
		TOKEN=$(cat "/config/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
            	WORKER=$(cat "/config/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_PATH="/config"
		CONFIG_FILE="bmminer.conf"
		fi
	fi
	if [ -f "/opt/scripta/etc/miner.conf" ]; then
		MODEL="BAIKAL"
		TOKEN=$(cat "/opt/scripta/etc/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
    		WORKER=$(cat "/opt/scripta/etc/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
		CONFIG_PATH="/opt/scripta/etc"
		CONFIG_FILE="miner.conf"
	fi
	# INNOSILICON
        if [ -d "/home/www/conf" ]; then
            ASIC="innosilicon"
            MINER="cgminer"
	    TOKEN=$(cat "/opt/scripta/etc/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
    	    WORKER=$(cat "/opt/scripta/etc/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
            CONFIG_PATH="/home/www/conf"
            CONFIG_FILE="miner.conf"
        fi
	# WHATSMINER
	if [ -d "/data/etc/config" ]; then
            MINER="cgminer"
	    CONFIG_FILE="pools"
	    CONFIG_PATH="/data/etc/config"
	    ASIC="whatsminer"
 	    TOKEN=$(cat "/data_bak/etc/config/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
    	    WORKER=$(cat "/data_bak/etc/config/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
        fi
  if [ -f "/www/luci-static/resources/braiinsOS_logo.svg" ]; then
    MODEL="BRAIINSOS"
    TOKEN=$(cat "/etc/minerstat/minerstat.txt" | grep TOKEN= | sed 's/TOKEN=//g')
    WORKER=$(cat "/etc/minerstat/minerstat.txt" | grep WORKER= | sed 's/WORKER=//g')
    CONFIG_PATH="/etc"
  fi
        POSTDATA=$(curl -s --insecure --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "ip=$LOCALIP" --data "data=$RESPONSE" https://api.minerstat.com/v2/get_asic)
        remoteCMD
    }

    # 5) CHECK SERVER RESPOSNE FOR POSSIBLE PENDING REMOTE COMMANDS
    remoteCMD() {

        SYNC_ROUND=$(($SYNC_ROUND + $SYNC_MAX))

	if [ -d "/var/www/html/resources" ]; then
		SYNC_ROUND=0
	fi

        if [ "$(printf '%s' "$POSTDATA")" != "NULL" ]; then
            echo "Remote command => $POSTDATA"
        fi
        # echo $RESPONSE

	#READ=$(cat "/$CONFIG_PATH/$CONFIG_FILE")
		# Update config on the 3th sync
		if [ ! -d "/data/etc/config" ]; then
			if [ "$SYNC_ROUND" != "135" ]; then
				echo ""
			else
			cd $CONFIG_PATH #ENTER CONFIG DIRECTORY
               		sleep 1 # REST A BIT
                #echo "NEW CONFIG => $NEWCONFIG";
                #if [ ! -z $NEWCONFIG ]; then
		if [ -d "/data/etc/config" ]; then
	    		CONFIG_FILE="pools"
	    		CONFIG_PATH="/data/etc/config"
      		fi
                echo "CONFIG => Updating $CONFIG_PATH/$CONFIG_FILE "
                rm "$CONFIG_PATH/$CONFIG_FILE"		
		rm "/tmp/tmpconf"
                curl -f --silent -L --insecure "http://static.minerstat.farm/asicproxy.php?token=$TOKEN&worker=$WORKER&type=$ASIC" > "/tmp/tmpconf"
		sleep 6
		CONFSIZE=$(cat "/tmp/tmpconf" | wc -l)
		if [ "$CONFSIZE" -gt "6" ]; then
			cp "/tmp/tmpconf" "$CONFIG_PATH/$CONFIG_FILE"
			cat "$CONFIG_PATH/$CONFIG_FILE"
		else
			echo "Config was blank, skip reboot"
		fi	
			fi
		fi

        if [ "$(printf '%s' "$POSTDATA")" = "CONFIG" ]; then
            if [ $CONFIG_FILE != "null" ]; then
                cd $CONFIG_PATH #ENTER CONFIG DIRECTORY
                sleep 1 # REST A BIT
                #echo "NEW CONFIG => $NEWCONFIG";
                #if [ ! -z $NEWCONFIG ]; then
		if [ -d "/data/etc/config" ]; then
	    		CONFIG_FILE="pools"
	    		CONFIG_PATH="/data/etc/config"
      		fi
                echo "CONFIG => Updating $CONFIG_PATH/$CONFIG_FILE "
                rm "$CONFIG_PATH/$CONFIG_FILE"		
		rm "/tmp/tmpconf"
                curl -f --silent -L --insecure "http://static.minerstat.farm/asicproxy.php?token=$TOKEN&worker=$WORKER&type=$ASIC" > "/tmp/tmpconf"
		sleep 6
		CONFSIZE=$(cat "/tmp/tmpconf" | wc -l)
		if [ "$CONFSIZE" -gt "6" ]; then
                	POSTDATA="REBOOT"
			cp "/tmp/tmpconf" "$CONFIG_PATH/$CONFIG_FILE"
			cat "$CONFIG_PATH/$CONFIG_FILE"
		else
			echo "Config was blank, skip reboot"
		fi	
                sleep 3
                echo "REBOOTING MINER..."
            	# SPONDS need reboot -f
            	if ! grep -q InnoMiner "/etc/issue"; then
        	if [ -f "/etc/cgminer.conf" ]; then
                	reboot -f
                fi
           	fi
                # Sponds end
           	/sbin/shutdown -r now
            	/sbin/reboot
            fi
        fi
        if [ "$(printf '%s' "$POSTDATA")" = "RESTART" ]; then
            if [ $ASIC = "antminer" ]; then
               auto echo "RESTARTING MINER..."
                sleep 2
                /etc/init.d/cgminer.sh restart
                /etc/init.d/bmminer.sh restart
            else
                POSTDATA="REBOOT"
            fi
        fi
        if [ "$(printf '%s' "$POSTDATA")" = "REBOOT" ]; then
            sleep 3
            echo "REBOOTING MINER..."
            # SPONDS need reboot -f
            if ! grep -q InnoMiner "/etc/issue"; then
        		    if [ -f "/etc/cgminer.conf" ]; then
                  reboot -f
                fi
            fi
            # Sponds end
            /sbin/shutdown -r now
            /sbin/reboot
        fi
        if [ "$(printf '%s' "$POSTDATA")" = "SHUTDOWN" ]; then
            sleep 2
            echo "SHUTTING DOWN..."
            /sbin/shutdown -h now
        fi

        # Wait after new sync round
	sleep 30
        check

    }


    #############################
    # SYNC LOOP

    echo "Staring the hub.. (10 sec)"
    sleep 10
    check

else
    echo "ERROR => Minerstat is already running! See: screen -x minerstat"
fi
