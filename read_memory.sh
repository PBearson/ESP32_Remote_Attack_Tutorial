#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

newline=$(echo "0a0d" | xxd -p -r) # \r\n

# Print the value at the address
printer="$newline%6\$s$newline" 

address=$(echo $1 | xxd -p -r)

payload=$address$printer

$command_prefix "$payload"