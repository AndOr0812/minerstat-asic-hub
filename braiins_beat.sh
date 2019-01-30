#!/bin/sh

# CURRENTLY ONLY USED FOR SPOND TO MAINTAIN UPTIME AND STABILITY

check() {
  CHECKHEALTH=$(ps | grep -c minerstat.sh)

  if [ "$CHECKHEALTH" != "1" ]
  then
  	echo ""
  else
  	nohup /bin/sh /etc/minerstat/minerstat.sh &
  fi

  #sleep 10
  #check

}

check
