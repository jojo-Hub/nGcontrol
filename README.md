# nGcontrol
openWRT package to have an overview and basic control about connected UMTS/GSM/LTE USB-dongles. The web interface gives an overview of certain connection parameters as well as provides some basic control to Stop, Start or restart a dongle. See attached screen shot for an example providing all three states of information.

Since sometimes, the dongles do not respond anymore, the mwan3-custom script was modified to "auto-reanimate" the dongle (i.e. turn it off and on physically). The maximum number of such retry attempts can be configured. Also, this script changes the behaviour of the WAN and USB LED of a D-Link DIR-825 router (should be quite customizable for any router).

To allow an one-to-one mapping between UMTS dongle, USB port and available interface, udev is used. This way you can use multiple SIM cards with certain billing plans and control their usage manually (or automatically via crontab).  

Right now, the version is just very basic, as just one model of huawei dongles is supported so far. Since they may have all the same API, it should be no problem to add other huawei dongles.

Also, only up to six dongles can be used right now. This is more a practical matter of resources: most usb hubs provide 7 ports and a dongle draws about 500mA which is quite the limit with a 3A power supply for the hub.



So far, the following USB dongles are supported:
  - 3372h

Hint: It is much easier to use dongles with highLink capabilitiy (i.e. they emulate a LAN interface and appeare as eth* on the router). nGcontrol uses these kind of dongles. For the huawei sticks to be accessible, you need to inserd a SIM card. For testing, you may also use a deactivated one. It is recommended to deactivate the PIN, otherwise an API function must enter the pin after every dongle's reboot (which is not implemented yet).
  

Prerequisites: 
  - lua socket lib
  - mwan3 package
  - USB hub which supports per-port power switching (PPPS) and uhubctl, compiled for openWRT (see SDK) *)
  - router with at least one free USB port and openWRT


*) It is planned to design an own PPPS functionality as an adapter to use any USB hub.

Some information about the environment:
  - WAN IP is from an 192.168.0.0/24 subnet
  - every UMTS dongle has the fix IP 192.168.x.1/24, where x denodes the USB port number, the dongle is plugged in to
  - on the routers side, the UMTS' emulated LAN connecton has the IP 192.168.x.2
  - the routers' LAN-bridge (i.e. local network) has the subnet 172.16.0.0./16


Some considerations for future versions:
  - If a certain traffic limit or configured date is approached, the router sends a SMS to a (list of) phone number(s). Similarly, still working dongles may inform about failures (such as max retry reached, dongle down all the time, etc.).
  - Allow to configure various dongle models (requires appropriate API) and create an config-page where you can chose the model. Also, modify the scripts to use a dynamic number of dongled (not at maximum 6 as nowadays).
  - Create a config page where the additional mwan3 parameters (retryMax, retryAttempt per interface) can be configured.
  - implement an auto-refresh function similar to the openWRT status overview page.
  - move the scripts from /root/scripts to a proper location, e.g. /usr/share/nGcontrol.
