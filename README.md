# ESP32 Remote Attack Tutorial

## Prerequisites

Install ESP-IDF version 4.4

Get VM

Set VM to Bridged Mode, then restart VM if needed.

Connect ESP32 to VM

Install mosquitto

```
sudo apt update && sudo apt install mosquitto mosquitto-clients
```

Confirm mosquitto is installed and running:

```
systemctl status mosquitto
```

```
netstat -tlpn | grep 1883
```

Finally, get the IP address of your VM:

```
ifconfig
```

This will list the network interfaces on your machine. You are interested in the Ethernet interface, typically named something like "eth0" or "ens33". The IP address of the interface is the address next to "inet".

## Build, Flash, and Test Projet

### Configure Project

Run menuconfig

```
idf.py menuconfig
```

Go to Example Configuration. This asks you for the URL of the MQTT broker to connect to. We want to connect to the mosquitto broker running on our VM, so set the value to your IP address. The structure of the field is mqtt://<IP address>. For example, in my case, it is mqtt://192.168.1.186.

Now go to Example Connection Configuration. This asks you to supply your WiFi connection information. Enter your SSID and password. There is no need to change any other settings. You can now exit and save the configuration.

### Build, Flash, and Monitor

Now build, flash, and monitor:

```
idf.py build flash monitor
```

If successful, you will see the ESP32 connect to your WiFi access point and subscribe to 2 MQTT topics: "/topic/qos0" and "/topic/qos1".

### Test Project

Without closing the ESP32 monitor, open a new termianl. In that new terminal, run the following command, which uses mosquitto_pub (a software for publishing MQTT messages) to publish a simple "Hello" message to the topic "/topic/qos0":

```
mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m "Hello"
```