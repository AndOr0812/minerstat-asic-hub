#!/bin/sh

# CURRENTLY ONLY USED FOR DAYUN TO MAINTAIN UPTIME AND STABILITY

REACH=0

check() {

REACH=$((REACH+1))

# NO PROCESS RUN MINERSTAT
if ! screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  echo "No process, Restart"
  screen -S minerstat -X quit # kill running process
  screen -S ms-run -X quit # kill running process
  screen -wipe
  screen -A -m -d -S minerstat sh /data_bak/etc/config/minerstat/minerstat.sh
  #exit
fi

# ONLY MS-RUN RUN MINERSTAT
if screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  echo "Frozen, restart"
  screen -S minerstat -X quit # kill running process
  screen -S ms-run -X quit # kill running process
  screen -wipe
  screen -A -m -d -S minerstat sh /data_bak/etc/config/minerstat/minerstat.sh
  #exit
fi

# ONLY MINERSTAT
if screen -list | grep -q "ms-run" && ! screen -list | grep -q "minerstat"; then
  echo "Frozen, restart (probably was fine, better to be secure)"
  screen -S minerstat -X quit # kill running process
  screen -S ms-run -X quit # kill running process
  screen -wipe
  screen -A -m -d -S minerstat sh /data_bak/etc/config/minerstat/minerstat.sh
  #exit
fi

# ALL FINE
if screen -list | grep -q "ms-run" && screen -list | grep -q "minerstat"; then
  echo "All fine"
fi

if [ "$REACH" = "3" ]; then
  REACH=0
  screen -S minerstat -X quit # kill running process
  screen -S ms-run -X quit # kill running process
  screen -wipe
  screen -A -m -d -S minerstat sh /data_bak/etc/config/minerstat/minerstat.sh
fi

sleep 20
check

}

check
