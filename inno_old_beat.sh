#!/bin/sh

# CURRENTLY ONLY USED FOR OLD INNO

check() {
  CHECKHEALTH=$(ps | grep -c minerstat.sh)

  if [ "$CHECKHEALTH" != "1" ]
  then
  	echo ""
  else
  	nohup /bin/sh /home/www/conf/minerstat/minerstat.sh &
  fi

  #sleep 10
  #check

}

check
