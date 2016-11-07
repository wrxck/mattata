#!/bin/bash
# Credit to Daniil Gentili for the original script, which is licensed under GPLv3
input="$1"
[ "$2" != "script" ]
conversationId=$(curl -s https://www.captionbot.ai/api/init | sed 's/"//g')
if [ ! -f "$input" ]; then
	url="\"$(curl -w "%{url_effective}\n" -L -f -s -I -S "$input" -o /dev/null | sed 's/^HTTP/http/g')\"" 2>/dev/null || { [ "$2" != "script" ] && echo "I'm afraid an error occurred. Please try again later."; exit 1; }
else
	[ "$2" != "script" ]
	url=$(curl -s https://www.captionbot.ai/api/upload -F "image1=@$input")
fi
mediainfo $(echo "$url" | sed 's/^\"//g;s/\"$//g') 2>/dev/null | grep -q Image || { [ "$2" != "script" ] && echo "I'm afraid an error occurred. Please try again later."; exit 1; }
[ "$2" != "script" ]
curl 'https://www.captionbot.ai/api/message' -H 'Host: www.captionbot.ai' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/json; charset=utf-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Referer: https://www.captionbot.ai/' -d '{"userMessage":'$url', "conversationId":"'$conversationId'"}'
result=$(curl -s 'https://www.captionbot.ai/api/message?waterMark=&conversationId='$conversationId -H 'Host: www.captionbot.ai' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-Requested-With: XMLHttpRequest' -H 'Referer: https://www.captionbot.ai/' -H 'Connection: keep-alive' | sed 's/\\"/"/g;s/^"//g;s/"$//g' | ./JSON.sh)
watermark=$(echo "$result" | sed '/\["WaterMark"\]/!d;s/\["WaterMark"\]\t//g')
message=$(echo "$result" | sed '/\["BotMessages",1\]/!d;s/\["BotMessages",1\]\t//g;s/^"//g;s/"$//g;s/\\n/ /g;s/\\//g')
[ "$2" = "script" ] && echo "$message" | grep -q "I really can't describe that picture" && exit 1
echo $message
exit 0