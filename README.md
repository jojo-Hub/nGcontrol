# nGcontrol
openWRT package to have an overview and basic control about connected UMTS/GSM/LTE USB-dongles. The web interface gives an overview of certain connection parameters as well as provides some basic control to Stop, Start or Restart a dongle. See attached screen shot for an example providing all three states of information.

Since sometimes, the dongles do not respond anymore, the mwan3-custom script was modified to "auto-reanimate" the dongle (i.e. turn it off and on physically). The maximum number of such retry attempts can be configured. Also, this script changes the behaviour of the WAN and USB LED of a D-Link DIR-825 router (should be quite customizable for any router).

To allow an one-to-one mapping between UMTS dongle, USB port and available interface, udev is used. This way you can use multiple SIM cards with certain billing plans and control their usage manually (or automatically via crontab).  

Right now, the version is just very basic, as just one model of huawei dongles is supported so far. Since they may have all the same API, it should be no problem to add other huawei dongles.

Also, only up to six dongles can be used right now. This is more a practical matter of resources: most usb hubs provide 7 ports and a dongle draws about 500mA which is quite the limit with a 3A power supply for the hub.



So far, the following USB dongles are supported:
  - Huawei 3372h

Hint: It is much easier to use dongles with highLink capabilitiy (i.e. they emulate a LAN interface and appeare as eth* on the router). nGcontrol uses these kind of dongles. For the huawei sticks to be accessible, you need to inserd a SIM card. For testing, you may also use a deactivated one. It is recommended to deactivate the PIN, otherwise an API function must enter the pin after every dongle's reboot (which is not implemented yet).
  

Prerequisites: 
  - lua socket lib
  - mwan3 package
  - udev
  - USB hub which supports per-port power switching (PPPS) and uhubctl, compiled for openWRT (see SDK) *)
  - router with at least one free USB port and openWRT

The software depencies can be installed with

 `# opkg update && opkg install kmod-usb-net-cdc-ether usb-modeswitch kmod-usb2 udev mwan3-luci`
 
Please note that udev needs to be [enabled](https://forum.openwrt.org/viewtopic.php?pid=135961#p135961) and some parameters have been added to /etc/config/{network, mwan, firewall}, see the corresponding example files.


*) It is planned to design an own PPPS functionality as an adapter to use any USB hub.

Some information about the environment:
  - WAN IP is from an 192.168.0.0/24 subnet
  - every UMTS dongle has the fix IP 192.168.x.1/24, where x denodes the USB port number, the dongle is plugged in to
  - on the routers side, the UMTS' emulated LAN connecton has the IP 192.168.x.2
  - the routers' LAN-bridge (i.e. local network) has the subnet 172.16.0.0./16. The only limitation for the LAN IP address range (and any private WAN range (e.g. if the router is behind another router)) is that it must not equal any of the gateways' subnets, i.e. it may be 192.168.y.0/24 where y>6.
