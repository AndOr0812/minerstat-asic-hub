#!/bin/sh
exec 2>/dev/null

sleep 1

screen -wipe

sleep 1

if ! screen -list | grep -q "ms-run" || [ "$1" = "forcestart" ]; then

    echo "--------- MINERSTAT ASIC HUB -----------"

    if ! screen -list | grep -q "ms-run"; then
    	# Fake Process, Boot & Double instance protection
    	screen -A -m -d -S ms-run sleep 7h
    fi
    
    # CRONTAB
    mkdir -p /var/spool/cron/crontabs 
    #echo "* * * * * screen -wipe" > /var/spool/cron/crontabs/root
    echo "* * * * * /bin/sh /config/minerstat/bitmain_beat.sh" > /var/spool/cron/crontabs/root
    start-stop-daemon -S -q -p /var/run/crond.pid --exec /usr/sbin/crond -- -l 9 

    sleep 10

    echo "-------- WAITING FOR CONNECTION -----------------"

    while ! ping minerstat.com -w 1 | grep "0%"; do
        sleep 1
    done

    # Remount filesystem
    mount -o remount,rw  / #remount filesystem

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

    LOCALIP="0.0.0.0"


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

        # ANTMINER
        if [ -d "/config" ]; then
            ASIC="antminer"
            CONFIG_PATH="/config"
            if [ -f "/config/cgminer.conf" ]; then
                MINER="cgminer"
            fi
            if [ -f "/config/bmminer.conf" ]; then
                MINER="bmminer"
            fi
            FOUND="Y"
	          # CHECK PROTECTOR HEALTH
	          CHECKHEALTH=$(ps | grep -c bitmain)
      	    if [ "$CHECKHEALTH" = "1" ]; then
             screen -A -m -d -S secure sh /config/minerstat/bitmain_beat.sh
            fi
        fi

        LOCALIP=$(/sbin/ifconfig eth0 | grep Mask | sed 's/^.*addr/addr/' | cut -f1 -d" " | sed 's/[^0-9.]*//g')
        LOCALIP="""$LOCALIP"

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
            QUERY=$(echo '{"command": "stats+summary+pools"}' | nc 127.0.0.1 4028)
            RESPONSE="""$QUERY "
	           if [ "$RESPONSE" != "timeout" ]; then
	    	         post
	           else
		             sleep 3
	    	         QUERY=$(echo '{"command": "stats+summary+pools"}' | nc 127.0.0.1 4028)
            	   RESPONSE="""$QUERY "
		             post
	           fi
    }

    # 4) SEND DATA TO THE SERVER
    post() {
    POSTDATA=$(curl -s --insecure --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "ip=$LOCALIP" --data "data=$RESPONSE" https://api.minerstat.com/v2/get_asic)
    remoteCMD
    }

    # 5) CHECK SERVER RESPOSNE FOR POSSIBLE PENDING REMOTE COMMANDS
    remoteCMD() {

        SYNC_ROUND=$(($SYNC_ROUND + $SYNC_MAX))

        if [ "$(printf '%s' "$POSTDATA")" != "NULL" ]; then
            echo "Remote command => $POSTDATA"
        fi
        # echo $RESPONSE

			if [ "$SYNC_ROUND" = "135" ]; then
			cd $CONFIG_PATH #ENTER CONFIG DIRECTORY
                sleep 1 # REST A BIT
                echo "CONFIG => Updating $CONFIG_PATH/$CONFIG_FILE "
                rm "$CONFIG_PATH/$CONFIG_FILE"
		rm "/tmp/tmpconf"
                curl -f --silent -L --insecure "http://static.minerstat.farm/asicproxy.php?token=$TOKEN&worker=$WORKER&type=$ASIC" > "/tmp/tmpconf"
		sleep 6
		CONFSIZE=$(cat "/tmp/tmpconf" | wc -l)
		if [ "$CONFSIZE" -gt "7" ]; then
			cp "/tmp/tmpconf" "$CONFIG_PATH/$CONFIG_FILE"
			# DEBUG
                	sleep 3
			cat "$CONFIG_PATH/$CONFIG_FILE"
		else
			echo "Config was blank, skip reboot"
		fi
			fi

        if [ "$(printf '%s' "$POSTDATA")" = "CONFIG" ]; then
            if [ $CONFIG_FILE != "null" ]; then
                cd $CONFIG_PATH #ENTER CONFIG DIRECTORY
                sleep 1 # REST A BIT
                echo "CONFIG => Updating $CONFIG_PATH/$CONFIG_FILE "
                rm "$CONFIG_PATH/$CONFIG_FILE"
		rm "/tmp/tmpconf"
                curl -f --silent -L --insecure "http://static.minerstat.farm/asicproxy.php?token=$TOKEN&worker=$WORKER&type=$ASIC" > "/tmp/tmpconf"
		sleep 6
		CONFSIZE=$(cat "/tmp/tmpconf" | wc -l)
		if [ "$CONFSIZE" -gt "7" ]; then
                	POSTDATA="REBOOT"
			cp "/tmp/tmpconf" "$CONFIG_PATH/$CONFIG_FILE"
			# DEBUG
                	sleep 3
			cat "$CONFIG_PATH/$CONFIG_FILE"
                	echo "REBOOTING MINER..."
           	  	/sbin/shutdown -r now
            	  	/sbin/reboot
		else
			echo "Config was blank, skip reboot"
		fi
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
            /sbin/shutdown -r now
            /sbin/reboot
        fi
        if [ "$(printf '%s' "$POSTDATA")" = "SHUTDOWN" ]; then
            sleep 2
            echo "SHUTTING DOWN..."
            /sbin/shutdown -h now
        fi

    }

    #############################
    # SYNC LOOP

    echo "Staring the hub.. (5 sec)"
    check
    sleep 5

    while true
	  do
	      sleep 45
	      check
	  done

else
    echo "ERROR => Minerstat is already running! See: screen -x minerstat"
fi
