![minerstat logo](https://cdn.rawgit.com/minerstat/minerstat-asic/master/docs/logo_full.svg)

# minerstat ASIC Hub

## What is this?
Monitoring and management client installed on the ASIC. The software makes possible to monitor your ASICs without any external monitoring software.

**Supported and tested ASICs:**
* Antminer A3
* Antminer B3
* Antminer D3 / D3 Blissz
* Antminer DR5
* Antminer E3
* Antminer L3+ / L3++
* Antminer S1-S9, S9i, S9j, S15 (All firmware)
* Antminer T9 / T9+
* Antminer X3
* Antminer Z9 / Z9-Mini
* Baikal B
* Baikal Giant
* Baikal N
* Baikal N240
* Baikal X
* Innosilicon A9 ZMaster
* Innosilicon D9 DecredMaster
* Innosilicon S11 SiaMaster
* Dayun Zig Z1
* Dayun Zig Z1+
* Spondoolies SPx36

Work in progress for more ASIC support.

## Tutorials

- [3 steps to set up ASIC Hub](https://medium.com/@minerstat/3-steps-to-set-up-asic-hub-a39a9803f0f2)
- [Antminer monitoring](https://medium.com/@minerstat/minerstat-mining-tutorial-20-antminer-monitoring-5882f7e362d9)
- [Innosilicon monitoring](https://medium.com/@minerstat/minerstat-mining-tutorial-23-innosilicon-monitoring-a667aff06a76)

## Installation & Update on Antminer, Innosilicon, Dayun, Baikal ASIC Miner

Login with SSH to your asic and execute the following command:
Make sure you replace **ACCESS_KEY** / **WORKER** to your details in the end of the above command. [Case sensitive!]

For **BAIKAL** need to run **sudo su** before installation. (You need to see root@ over SSH not baikal@)

``` sh
cd /tmp && wget -O install.sh http://static.minerstat.farm/github/install.sh && chmod 777 *.sh && sh install.sh ACCESS_KEY WORKER
```

## Install on Spondoolies ASIC Miner

Login with SSH to your asic and execute the following command:
Make sure you replace **ACCESS_KEY** / **WORKER** to your details in the end of the above command. [Case sensitive!]

``` sh
cd /tmp && curl --insecure -H 'Cache-Control: no-cache' -O -s https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/install.sh && chmod 777 *.sh && sh install.sh ACCESS_KEY WORKER
```

Default SSH Login

| ASIC          | Username  | Password        |
| ------------- |:---------:| ---------------:|
| Antminer      | root      | admin           |
| Baikal        | baikal    | baikal          |
| Innosilicon   | root      | innot1t2        |
| Innosilicon   | root      | t1t2t3a5        |
| Innosilicon   | root      | blacksheepwall  |
| Dayun         | root      | envision        |
| Spondoolies   | root      | root            |

## Bulk Installation from Linux Computer [ or from msOS]
``` sh
cd /tmp && wget -O bulk.sh https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/bulk-install.sh && chmod 777 *.sh && sh bulk.sh
```

First you need to import and/or add manually your workers to the website.
The bulk install script will ask your **ACCESS_KEY** and **GROUP/LOCATION** only. The rest of process is automatic.

### You want to re-run the bulk install script on your location ?

The bulk install is designed to skip already installed machines. If you want to do a **force bulk install** use this command:

``` sh
cd /tmp && wget -O bulk.sh https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/bulk-install.sh && chmod 777 *.sh && sh bulk.sh force
```

### Antminer S9 Bulk Firmware Update from Ubuntu (to Support Asic Boost)

Read "Bulk installation from Linux Computer" first.

``` sh
cd /tmp && wget -O firmware.sh https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/bulk-firmware.sh && chmod 777 *.sh && sh firmware.sh
```

## How the software works?

<img src="https://raw.githubusercontent.com/minerstat/minerstat-asic-hub/master/docs/works-asic-hub.svg?sanitize=true" width="65%">


## Uninstall
``` sh
cd /tmp && wget -O uninstall.sh http://static.minerstat.farm/github/uninstall.sh && chmod 777 *.sh && sh uninstall.sh
```

## 

***© minerstat OÜ*** in 2018


***Contact:*** app [ @ ] minerstat.com 


***Mail:*** Sepapaja tn 6, Lasnamäe district, Tallinn city, Harju county, 15551, Estonia

## 
