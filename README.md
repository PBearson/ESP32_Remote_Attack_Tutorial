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

## Inject Malicious String into Program
  
Now we will see how to inject data (in the form of a string) into a program through a well-known attack called **Format String Attack**. A format string attack can occur when certain functions do not format user input correctly. For example, `printf("%s, input)` is safe, while `printf(input)` is vulnerable to the attack. More details on format string attacks (for x86 architecture) are available here: https://web.ecs.syr.edu/~wedu/Teaching/cis643/LectureNotes_New/Format_String.pdf
  
This MQTT application is vulnerable to the format string attack. See line 98 of the main file: https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/86b7400b642051719e6b2161f4da7cff6dcaf6b0/main/app_main.c#L98

  To perform the attack, there are two shell scripts in this project. The first script, `inject_payload.sh`, will inject the string "You are hacked!" into memory address 0x3ff80101. The address range 0x3ff80000 - 0x3ff81fff is reserved for RTC FAST memory, which is memory that persists through the ESP32's deep sleep mode. Since our application does not use deep sleep, this memory region is empty. The second script, `print_payload.sh`, will print the injected string.
