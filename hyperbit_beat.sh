#!/bin/sh

# CURRENTLY ONLY USED FOR HYPERBIT TO MAINTAIN UPTIME AND STABILITY

check() {

  sleep 20

  CHECKHEALTH=$(ps aux | grep -c minerstat.sh)

  if [ "$CHECKHEALTH" != "1" ]
  then
  	echo ""
  else
  	nohup /bin/sh /usr/app/minerstat/minerstat.sh &
  fi

  check

}

check
