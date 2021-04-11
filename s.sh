#!/bin/bash
urls=cc.vimeo
y=$(wc -l $urls |grep -Eo [0-9]+);
echo $y;
counter=1;
mkdir ~/vimeo/
while [ $counter -le $(echo $y) ]
do
while IFS= read -r line; do
    wget $line --output-document example$counter.html
     echo $counter

counter=$((counter+1))
done < $urls
done
counter=$((counter-1))
x=1
while [ $x -le $(echo $counter) ]
do
cat example$x.html | grep -Eo https://vod-progressive.akamaized.net/exp=[0-9]+~acl=%2Fvimeo-prod-skyfire-std-us[%0-9a-zA-Z.]+.mp4~hmac=[a-zA-Z0-9]+/vimeo-prod-skyfire-std-us/01[0-9a-z/]+.mp[0-9]+ |anew file$x.out
xargs -n 1 curl --head < file$x.out | grep -E Length | awk '{print $2}' | anew lfile$x.out
maxnum=$(sort -n lfile$x.out |tail -1)
z=$(grep -n $maxnum lfile$x.out | grep -Eo '^[^:]+')
url=$(sed -n "$z p" file$x.out)
wget -r -c $url --output-document video$x.mp4
x=$((x+1))
done