#!/bin/sh
exec 2>/dev/null

# CURRENTLY ONLY USED FOR SPOND TO MAINTAIN UPTIME AND STABILITY

check() {

screen -wipe &> /dev/null

sleep 1

# NO PROCESS RUN MINERSTAT
if ! screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  #echo "No process, Restart"
  screen -S minerstat -X quit &> /dev/null
  screen -S ms-run -X quit &> /dev/null
  screen -wipe &> /dev/null
  screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh
  #exit
fi

# ONLY MS-RUN RUN MINERSTAT
if screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  #echo "Frozen, restart"
  screen -S minerstat -X quit &> /dev/null
  screen -S ms-run -X quit &> /dev/null
  screen -wipe &> /dev/null
  screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh
  #exit
fi

# ONLY MINERSTAT NO MS-RUN
if ! screen -list | grep -q "ms-run" && screen -list | grep -q "minerstat"; then
  #echo "Frozen, restart"
  screen -S minerstat -X quit
  screen -S ms-run -X quit
  screen -wipe
  screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh
  #exit
fi

# ONLY MINERSTAT
if screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  #echo "Frozen, restart (probably was fine, better to be secure)"
  screen -S minerstat -X quit &> /dev/null
  screen -S ms-run -X quit &> /dev/null
  screen -wipe &> /dev/null
  screen -A -m -d -S minerstat sh /config/minerstat/minerstat.sh
  #exit
fi

sleep 30
check

}

check
