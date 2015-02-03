#!/bin/bash

# This script checks that each BSSID of a list of APs is valid, i.e. that the
# Google API knows it.
#
# Possible bugs: if the first AP is wrong, we'll have to fix that by hand.
# Possible enhancement: use distance wth real location as well

if [ "$#" != "1" ]
then
    echo "Usage: $0 <filename>"
    exit 1
fi

if [ -f ./config.sh ]
then
    . ./config.sh
else
    echo "File config.sh not found. Please copy config.sh.example and provide all required information (cf. README.md)"
    exit;
fi

filename="$1"
nb_lines=$(cat "$filename" | wc -l)
tmpfile=$(mktemp)
tmpfile2=$(mktemp)

# Create a new file with filtered output
sed -n '1p' "$filename"

for i in $(seq 2 $nb_lines)
do
    sed -n '1p' "$filename" > "$tmpfile"
    line=$(sed -n "${i}p" "$filename")
    echo "$line" >> "$tmpfile"
    ./convert_to_google_api.pl "$tmpfile" > "$tmpfile2"
    res=$(curl -d @"$tmpfile2" -H "Content-Type: application/json" -i "https://www.googleapis.com/geolocation/v1/geolocate?key=$api_key" 2>/dev/null)

    lat=$(echo $res | sed -r 's/.*"lat": (-?[0-9\.]+).*/\1/')
    long=$(echo $res | sed -r 's/.*"lng": (-?[0-9\.]+).*/\1/')
    acc=$(echo $res | sed -r 's/.*"accuracy": ([0-9\.]+).*/\1/')
    acc_int=$(echo $res | sed -r 's/.*"accuracy": ([0-9]+).*/\1/')
    if [ "$acc_int" -gt 2000 ]
    then
	echo -ne "\033[01;31m*** Wrong AP: "	1>&2
	echo -n "$line"				1>&2
	echo -e " ***\033[0m"			1>&2
    else
	echo "$line"
    fi
done
