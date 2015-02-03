geoloc_attack
=============

Attack on the geolocation system - PoC

Allows an attacker to generate a fake environment of Wi-Fi access
points for a target device (identified by its MAC address) in order to
modify its geolocation and get its owner's Twitter account.

Associated paper is yet to be published.

## Install ##

To make it work:
- download and install this version of aircrack:
  https://github.com/Perdu/aircrack-ng
  Note that it contains experimental features which may break regular use of
  aircrack, so probably do not want to keep it afterwards.
- download Phirehose and put it in current folder:
  git clone https://github.com/fennb/phirehose
- copy config.sh.example to config.sh
- copy config.php.example to config.php
- you must have a wireless interface supporting monitor mode and packet
  injection (if it is not called wlan0, modify config.sh)
- You must provide OAuth data and credentials for the Twitter API in
  config.php: see for instance https://dev.twitter.com/discussions/631
- you must provide a Google API key in config.sh. See for instance
  http://www.w3schools.com/googleapi/google_maps_api_key.asp
- We provide a cookie to use Wigle. As Wigle limits the number of queries to
  about 10-20 requests per account *or* per IP, chances are the default cookie
  will already have been used by somebody else when you try to use it. In that
  case, you will have to create an account and provide the associated cookie.
- Due to API changes in Wigle, the get_ssid_list.pl script now requires the
  JSON::Parse perl module, which does not seem to be packaged in most
  distributions. To install it, run cpan, then type "install JSON::Parse".

Once everything is set up, launch full_attack.sh <lat> <long> <target_mac>
Then check that the location is indeed modified on target device.

## Parts of the script ##
All files of the script can be used as standalone files, and have various
command line parameters (use -h to see a help for each of them)
- get_ssid_list.pl: a Wigle crawler
- get_current_ssid.pl: makes a scan of visible access points and display only
  useful information (MAC address, SSID, and channel with -m flag)
- convert_to_google_api.pl: convert a list of AP to a JSON file for the Google
  Geolocation API
- filter-track-geo.php: monitors a location and display tweets from that
  location
- filter_ap_list.sh: checks that every access point in a list is known by the
  Google API (note: assumes that the first one is correct; otherwise it will
  fail)

## To do ##
- Switching some options from the config file to command line parameters with
  a nice Getopt like in get_ssid_list.pl could be nice.
- Integrate the aircrack patch into core aircrack-ng
- make a patch for mdk3 to allow selecting a single target
