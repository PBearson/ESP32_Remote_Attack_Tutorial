# ESP32 Software Security Demo

This project demonstrates how to remotely exploit a well-known software vulnerability called the **Format String Attack**. The attack allows users to arbitrarily read and write memory. We will show two examples of how to perform a remote attack on the ESP32. In the first example, we will write a malicious string "You are hacked!" into memory and then print the string out. In the second example, we will overwrite a global variable called `username` that influences the behavior of the program. As a case study, we will use a vulnerable MQTT application that subscribes to some topics, allowing users to communicate remotely with the ESP32.

## Prerequisites

Follow [these instructions](https://docs.espressif.com/projects/esp-idf/en/v4.4.1/esp32/get-started/index.html) to install ESP-IDF version 4.4.

Change the network settings in your VM so that it uses Bridged mode instead of NAT mode. Bridged mode allows other devices in your network to communicate with your VM, which will be important later. If needed, you can restart your VM to reset the network configuration.

In your VM, open a terminal and install mosquitto, which is a popular MQTT application:

```
sudo apt update && sudo apt install mosquitto mosquitto-clients
```

On Ubuntu, installing mosquitto should automatically start running it as a service on port 1883. You can confirm this by running the following command:

```
systemctl status mosquitto
```

If you see "active (running)" in green letters, then mosquitto is running.

Alternatively, you can check that port 1883 is open and listening on your system by running the following command:

```
netstat -tlpn | grep 1883
```

Finally, we need to retrieve the IP address of the VM. To do this, run the following command:

```
ifconfig
```

This will list the network interfaces on your machine. We are only interested in the Ethernet interface, typically named something like "eth0" or "ens33". The IP address of the interface is the address next to "inet". Make a note of this address.

Now download this project:

```
git clone https://github.com/PBearson/ESP32_Remote_Attack_Tutorial.git
```

## Build, Flash, and Test Project

### Configure Project

Navigate to the root directory of this project, and open the configuration menu:

```
idf.py menuconfig
```

Go to Example Configuration. This asks you for the URL of the MQTT broker to connect to. We want to connect to the mosquitto broker running on our VM, so set the value to your IP address. The structure of the field is mqtt://\<IP address\>. For example, in my case, it is mqtt://192.168.1.186. Note that the ESP32 can only connect to the broker if our VM uses the Bridged networking mode.

Now go to Example Connection Configuration. This asks you to supply your WiFi connection information. Enter your SSID and password. There is no need to change any other settings.
  
Now exit and save the configuration.

### Build, Flash, and Monitor

To build, flash, and open the serial monitor, run the following command:

```
idf.py build flash monitor
```

If successful, you will see the ESP32 connect to your WiFi access point and subscribe to 2 MQTT topics: "/topic/qos0" and "/topic/qos1".

### Test Project

Without closing the ESP32 monitor, open a new terminal. In that new terminal, run the following command, which uses mosquitto_pub (a software for publishing MQTT messages) to publish a simple "Hello" message to the topic "/topic/qos0":

```
mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m "Hello"
```

## Attack 1: Inject Malicious String into Program
  
Now we will see how to inject data (in the form of a string) into a program through a well-known attack called **Format String Attack**. A format string attack can occur when certain functions do not format user input correctly. For example, `printf("%s, input)` is safe, while `printf(input)` is vulnerable to the attack. More details on format string attacks (for x86 architecture) are available here: https://web.ecs.syr.edu/~wedu/Teaching/cis643/LectureNotes_New/Format_String.pdf
  
This MQTT application is vulnerable to the format string attack. See line 98 of the main file: https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/86b7400b642051719e6b2161f4da7cff6dcaf6b0/main/app_main.c#L98

  To perform the attack, there are two shell scripts in this project. The first script, `inject_payload.sh`, will inject the string "You are hacked!" into memory address 0x3ff80101. The address range 0x3ff80000 - 0x3ff81fff is reserved for RTC FAST memory, which is memory that persists through the ESP32's deep sleep mode. Since our application does not use deep sleep, this memory region is empty. The second script, `print_payload.sh`, will print the injected string.

  To execute the first script, run the following command in your second terminal:
  
  ```
  bash inject_payload.sh
  ```
  
  This command uses mosquitto_pub to publish the following payload (in binary) to the ESP32:
  
  ```
 0101f83f0201f83f0301f83f0401f83f0501f83f0601f83f0701f83f0801
f83f2001f83f2001f83f0b01f83f0c01f83f0d01f83f0e01f83f0f01f83f
1001f83f2532357825362468686e2532327825372468686e253236327825
382468686e253137317825392468686e25333231782531302468686e2531
37782531312468686e25323433782531322468686e253138377825313324
68686e25333238782531342468686e25323439782531352468686e253235
38782531362468686e2538782531372468686e2532353078253138246868
6e25323535782531392468686e25313839782532302468686e2532323378
2532312468686e0a
  ```
  
  You will see the ESP32 appear to print random memory addresses, like so:
  
  ![image](https://user-images.githubusercontent.com/11084018/164243528-33a45a36-f475-48de-b3e4-a814d7a23289.png)
  
  In reality, this is a side effect of carefully selecting which bytes to inject into memory. It will be explained later.
  
  To execute the second script, run the following command:
  
  ```
  bash print_payload.sh
  ```
  
  This command will use mosquitto_pub to publish the following payload (in binary) to the ESP32:
  
  ```
  0101f83f200d25362473200d0a
  ```
  
  In the ESP32 monitor, you should see the injected string print out to the console:
  
  ![image](https://user-images.githubusercontent.com/11084018/164245035-4f3e36c7-c9dc-4a2f-bf62-eeefe79d9b87.png)
  
  If you do not see the string, then simply run the script again. The RTC FAST region is accessed exclusively by the ESP32's PRO_CPU core, while the normal application is executed by the APP_CPU core. This means that executing `printf` and reading the string happen on different CPU cores, and sometimes the `printf` function will return before the string has been retrieved from memory.

  As a side note, if you are interested in displaying precisely what data is sent to the ESP32, you can convert either payload back to its binary form with the following commands:
  
  ```
  echo <payload> | xxd -p -r
  ```
  
  ![image](https://user-images.githubusercontent.com/11084018/164247098-3ddc4f81-67eb-419e-8ae8-5eb262e5e5b9.png)
  
  ![image](https://user-images.githubusercontent.com/11084018/164247413-8305880f-aa21-44e3-87d0-e59b6b85fdc4.png)


  
  ### Explanation of `inject_payload.sh`
  
  The `inject_payload.sh` script crafts a payload that essentially has the following structure:
  
  ```
  <address 1>, i.e., 0x3ff80101
  <address 2>, i.e., 0x3ff80102
  ...
  <address 16>, i.e., 0x3ff80110
  <format string to inject 'Y' into address 1>
  <format string to inject 'o' into address 2>
  <format string to inject 'u' into address 3>
   ...
  <format string to inject '!' into address 15>
  <format string to inject '\0' into address 16>
  ```
  
  By placing the addresses at the beginning of the buffer, the format string attack will actually place those addresses onto the stack. The `<format string to inject...>` lines will reference the stack at different offsets, so by preemptively placing the addresses onto the stack, we can write to them. For example, `%6$hhn` will write data to the first address on the stack, `%7$hhn` will write to the second address, and so forth. There are methods to carefully control what data is written, which will be explained shortly. Now the rest of this section will explain the `inject_payload.sh` script line by line.

  Line 3 sets the mosquitto_pub command prefix, which prepares our script to send a message to the "/topic/qos0" topic:
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L3
  
  Lines 5 - 20 prepare the memory addresses we will need for the attack. We create addresses 0x3ff80101 - 0x3ff80110. Each address will correspond to a byte from our malicious string, including the null terminator. The address bytes are reversed since the ESP32 uses little endian addressing.
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L5-L20
  
  Line 23 combines all addresses together into a single variable:
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L23
  
  Lines 25 through 40 write the bytes into the addresses. To control what data is written to each address, we use the "%Nx" parameter (where N is an integer) to increase the number of characters written by `printf` by N bytes. Then when the "%M$hhn" parameter (where M is another integer) is executed, the value written to the address is the number of characters written so far. Further explanation is given below.
    
 For the first address, 0x3ff80101, we want to write the character 'Y'. This has hex value 0x59, or decimal value 89. Therefore, we need to first get `printf` to write 89 characters. Since we use the "%hhn" parameter, which specifies a one-byte write width, it is also okay to write any number of characters where the least significant byte is 0x59, e.g., 0x159, 0x259, 0x359, etc., and it will only write 0x59. Since our buffer begins with 16 addresses, each of which is 4 bytes long, `printf` will have already printed 64 characters. To write the value 89, we can use the "%25x" parameter to print 25 more characers. This also has the effect of printing out register A11, which is traditionally the second argument passed to `printf`. Then we use the "%6\$hhn" parameter to write the value 89 to address 0x3ff80101. Note that we need to escape the $ symbol, since this symbol is typically used in shell scripts to reference variables. Also note that using the "%M$hhn" format string does not contribute to the number of bytes written by `printf`.
    
 For the second address, 0x3ff80102, we want to write the character 'o'. This has hex value 0x6f, or decimal value 111. Therefore, we need to print out 22 more characters. Using the parameter "%22x%7\$hhn", we print out 22 more characters (111 total) and write this value to address 0x3ff80102. It also has the effect of printing out register A12, which is traditionally the third argument passed to `printf`.
    
For the third address, 0x3ff80103, we want to write the character 'u'. This has hex value 0x75, or decimal value 117. At first glance, it may seem that we need to print out exactly 6 more characters. However, if we try to use the parameter "%6x", this will print out the contents of register A13, which may be a 32-bit value. For example, it may contain an address such as `3f4036d8`. Although the address itself is only 4 bytes, `printf` will print it as a string, which is 8 bytes. Therefore, the "%6x" parameter could potentially print out an additional 8 bytes instead of the desired 6 bytes. To avoid this issue, instead of trying to print 0x75, we can print 0x175, or 373. Thus, we can print an additional 262 bytes. The full parameter is "%262x%8\$hhn", which increases the number of characters printed to 373 and writes the least significant byte (0x75) to address 0x3ff80103.
    
 For addresses 0x3ff80104 through 0x3ff80110, we repeat this process, using the "%Nx" paramater to increase the number of bytes printed by `printf` and writing that value to each corresponding address. It will also print out the contents of register A14 (fifth `printf` argument), A15 (sixth `printf` argument), the stack value pointed to by the stack pointer (seventh argument), SP + 4 (eighth argument), SP + 8, and so forth. This is why we see some of the addresses we injected onto the stack when we observe the console output.
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L25-L40
    
Line 43 combines lines 25 through 40 into a single variable:
    
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L43
    
Line 46 crafts the final payload by combining the addresses with the format string parameters:
    
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L46
    
Optionally, lines 49 through 52 print a hexdump of the payload if the user supplies an argument to the script, for example, `sh inject_payload.sh 1`:
     
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L49-L52
    
Finally, line 54 combines the mosquitto_pub command with the payload. The payload becomes the message that is published to the "/topic/qos0" topic.
    
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/605baf042e11948bfcca83b64565830069b863e3/inject_payload.sh#L54
    
 ### Explanation of `print_payload.sh`
    
 The `print_payload.sh` script crafts a payload with the following structure:
    
```
<address 1>, i.e., 0x3ff80101
<format string to print address 1 as a string>
```

  Line 3 constructs the mosquitto_pub command prefix in the same way as before:
  
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L3
  
 Line 5 constructs the newline escape sequence, i.e., \r\n. This has hex value 0xd0a, and we reverse the bytes due to the little endianness.
  
https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L5
  
  Line 7 places the address 0x3ff80101 onto the stack. Note that this is the start address of our injected string.
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L7
  
  Line 10 casts the address 0x3ff80101 as a string and prints it out by using the parameter "%6$s". In C, a string is also known as a character pointer, so this will print out the value _pointed to_ by 0x3ff80101, which is our malicious string. It will continue to print characters until it hits the null terminator, which is why we intentionally injected the null byte at the end of our string. Also note that we surround our parameter with newline escape sequences, so that our string is guaranteed to print on a new line.
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L10
  
  Line 13 constructs the payload by combining the address with the format string:
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L13
  
  Optionally, lines 16 through 19 print a hexdump of the payload if the user supplies an argument to the script, for example, `sh print_payload.sh 1`:
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L16-L19
  
  Finally, line 21 combines the mosquitto_pub command with the payload. The payload becomes the message that is published to the "/topic/qos0" topic.
  
  https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/13cb0294852cdd885824382b0da537cd912fb773/print_payload.sh#L21

## Attack 2: Overwrite Data in Program

In this attack, we will overwrite a global variable `username` in the program and change its behavior at runtime. Line 35 shows the initial definition of `username`. It is a character array of size 8.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/8ecb74812f1ed7fee75b1221733c3785e5c3eee2/main/app_main.c#L35

In the `app_main` function, the string "esp32" is copied over to `username`.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/8ecb74812f1ed7fee75b1221733c3785e5c3eee2/main/app_main.c#L189

In the `mqtt_event_handler` function, the app checks the value of `username` every time it receives a message from one of its subscribed topics. If the name is set to "root", and if the received message was "ping", then the app will respond by publishing a message "PING FROM ESP32" to the topic "/topic/root".

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/8ecb74812f1ed7fee75b1221733c3785e5c3eee2/main/app_main.c#L103-L107

The goal of this attack is to satisfy the `if` statement above and execute the publish command without changing the source code. To aid in this attack, there are two helper scripts provided. The first script, `read_memory.sh`, reads a string from a user-specified memory address. This will help us to confirm where the `username` string is located in memory. The second script, `write_memory.sh`, writes the string "root" to a user-specified memory address.

Before executing either script, we need to find the address of `username` in memory. We can use the `readelf` command to analyze the symbol table of our application and try to find `username`. Run the following command:

```
readelf -s build/mqtt_tcp.elf | grep username
```

In the output, you will see various information about the symbol, including its memory address in the second column. Make a note of the address.

![image](https://user-images.githubusercontent.com/11084018/164498855-81d2ea1a-24fe-4b97-aa4d-eaa83430ac8c.png)

Now we will execute the `read_memory.sh` script to confirm that `username` is allocated to the address we found. For this example, I will assume the address is 0x3ffb5408. First, make sure that the applicaton is running in a separate terminal. Now run the script, and pass the memory address as an argument. The script expects little-endian format, so make sure the address is formatted correctly; for example, 0x3ffb5408 should be written as "0854fb3f".

```
bash read_memory.sh 0854fb3f
```

If done correctly, you will see the ESP32's serial monitor print out "esp32", which is the current value of `username`.

![image](https://user-images.githubusercontent.com/11084018/164502167-adc4ced4-04a3-43ac-806b-d69c78434479.png)

Now that we confirmed exactly where `username` is in memory, we can use the `write_memory.sh` script to overwrite it:

```
bash write_memory.sh 0854fb3f
```

Now execute `read_memory.sh` again to see if `username` has changed:

```
bash read_memory.sh 0854fb3f
```

If successful, the serial monitor will now print out "root", which is the new value of `username`!

![image](https://user-images.githubusercontent.com/11084018/164506765-48b71973-599b-4725-a304-cb20729f1306.png)

Finally, to satisfy the `if` statement from before, send a "ping" message to the "/topic/qos0":

```
mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m ping
```

The serial monitor will print a message indicating that a publish event has just occurred. This seemingly confirms that our attack worked.

![image](https://user-images.githubusercontent.com/11084018/164507129-3b42d60d-29a5-4c46-a51a-dd663ab7d924.png)

To make sure the attack works, we can subscribe to the "/topic/root" topic ourselves. Open a third terminal and use mosquitto_sub to subscribe to the topic:

```
mosquitto_sub -h 0.0.0.0 -t "/topic/root"
```

Now publish the "ping" message again:


```
mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m ping
```

You should see mosquitto_sub receive the "PING FROM ESP32" message. This confirms that the attack worked!

![image](https://user-images.githubusercontent.com/11084018/164509820-7e9ba38a-0daf-45fc-b1f6-4de825fa12fe.png)

### Explanation of `read_memory.sh`

The `read_memory.sh` script crafts a payload that is almost exactly identical to `print_payload.sh`. The only difference is that the address is user-controlled instead of fixed.

Line 13 constructs the address supplied from user input. Note that the address must be little-endian formatted:

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/d5a63195190ea73825cfb251dfb982ae2a125616/read_memory.sh#L13

The rest of the file is identical to `print_payload.sh` and will not be explained here.

### Explanation of `write_memory.sh`

The `write_memory.sh` script crafts 5 different payloads with the following structure:

```
<base_address + i>, where i ranges from 0 to 4
<format string to inject a byte into base_address + i>
```

Here, `base_address` is the address provided by the user. This script injects the "root" string into the desired address. Therefore, the script injects "r" into `base_address`, "o" into `base_address + 1` and `base_address + 2`, "t" into `base_address + 3`, and the null byte into `base_address + 4`. In this case, `base_address` should be set to the address of `username` in order to overwrite that data.

Line 7 retrieves the 3 most significant bytes (MSB) from the supplied address. Due to the formatting, these are the last 6 characters in the address string. For example, if the supplied address is "0854fb3f", then this command retrieves "54fb3f".

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L7

Line 8 obtains the least significant byte (LSB) from the user-supplied address. These are the first 2 characters in the address string. For example, if the supplied address is "0854fb3f", then this command retrieves "08".

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L8

Lines 10 through 13 specify the format strings needed to write "r", "o", "t", and the null byte into memory. The assumption is that these format strings are preceded by a memory address, so `printf` will have already printed 4 bytes by the time the format strings are executed. For example, the hex value of "r" is 0x72, so we can print an additional 110 (0x6e) bytes to write "r" into memory. 

Since each character is written to memory in a separate payload (i.e., we call `printf` separately for each character), the number of bytes printed by `printf` always starts at 4 when the format string is executed.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L10-L13

Lines 16 through 40 contain a `for` loop that iterates over the numbers 0 through 4, and `i` holds the current loop iteration. The loop is explained further below.

In lines 19 and 20, the LSB is converted from string to integer, incremented by `i`, and converted back to a string.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L19-L20

In line 23, the address is constructed by combining the LSB with the MSB.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L23

In lines 26 through 34, we select the format string depending on which iteration we are in the loop (i.e., the value of `i`). The format strings were previously defined in lines 10 through 13. For example, when `i` = 0, we select the format string that writes "r" into memory; when `i` = 1, we select the format string that writes "o" into memory; and so forth.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L26-L34

Finally, line 37 crafts the payload by combining the address with the format string. Line 38 sends the payload.

https://github.com/PBearson/ESP32_Remote_Attack_Tutorial/blob/1c9cf0196219d0334bda2f7ee3f9865b7d442892/write_memory.sh#L37-L38
