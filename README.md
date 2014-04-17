geoloc_attack
=============

Attack on the geolocation system - PoC

Allows an attacker to generate a fake environment of Wi-Fi access
points for a target device (identified by its MAC address) in order to
modify its geolocation and get its owner's Twitter account.

Associated paper is yet to be published.

To make it work:
- download aircrack, patch it with aircrack_patch_attack.txt, and install it
- download Phirehose and put it in current folder: git clone https://github.com/fennb/phirehose
- copy config.sh.example to config.sh
- copy config.php.example to config.php
- you must have a wireless interface supporting monitor mode and packet
  injection (if it is not called wlan0, modify config.sh)
- You must provide OAuth data and credentials for the Twitter API in
  config.php: see for instance https://dev.twitter.com/discussions/631
- you must provide a Google API key in config.sh. See for instance http://www.w3schools.com/googleapi/google_maps_api_key.asp
- We provide a cookie to use Wigle. As Wigle limits the number of queries to
  about 10-20 requests per account *or* per IP, chances are the default cookie
  will already have been used by somebody else when you try to use it. In that
  case, you will have to create an account and provide the associated cookie.
