#!/bin/sh

# CURRENTLY ONLY USED FOR WHATSMINER TO MAINTAIN UPTIME AND STABILITY

check() {

  sleep 20

  CHECKHEALTH=$(ps | grep -c minerstat.sh)

  if [ "$CHECKHEALTH" != "1" ]
  then
  	echo ""
  else
  	nohup /bin/sh /data/etc/config/minerstat/minerstat.sh &
  fi

  check

}

check
