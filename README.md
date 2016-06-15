# nGcontrol
openWRT package to have an overview and basic control about connected UMTS/GSM/LTE USB-dongles. The web interface gives an overview of certain connection parameters as well as provides some basic control to Stop, Start or restart a dongle.

Since sometimes, the dongles do not respond anymore, the mwan3-control script was customised to "auto-reanimate" the dongle. The maximum number of such retry attempts may be configured.
To allow an one-to-one mapping between UMTS dongle, USB port and available interface, udev is used. This way you can use multiple SIM cards with certain billing plans and control their usage manually (or automatically via crontab).  



Right now, the version is just very basic, as just one model of huawei dongles is supported so far. Since the may have all the same API, it should be no problem to add other huawei dongles.

Also, only up to six dongles can be configured (most usb hubs provide 7 ports and a dongle draws about 500mA which is quite the limit with a 3A power supply for the hub).



So far, the following USB dongles are supported:
  - 3372h
  

Prerequisites: 
  - lua socket lib
  - mwan3 package
  - USB hub which supports per-port power switching (PPPS) and uhubctl, compiled for openWRT (see SDK) *)
  - router with at least one free USB port and openWRT


*) It is planned to design an own PPPS functionality as an adapter to use any USB hub.
