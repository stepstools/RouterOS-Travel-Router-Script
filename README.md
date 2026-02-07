# RouterOS-Travel-Router-Script
RouterOS terminal script to easily configure the device as a "travel router."

## Background
I bought a hAP ax2 to use as my travel router and it was my first venture into the RouterOS ecosystem.  I was frustrated by how difficult it was to swap between using the 5GHz and 2.4GHz radios as the WAN.  This script is the result of that frustration.  Disclaimer: I am not an expert in RouterOS scripting, so no promises that this actually works for you.  Improvements and PRs from more experienced users are appreciated.

## Assumptions:
This script was written for the hAP ax2.  YMMV for other devices.  Recommend running this script from a default-ish configuration for best results.
1. Script only tested on RouterOS 7.21.2
2. ether1 used as WAN ethernet port and rejoins the LAN bridge when wifi1/2 is WAN.
3. ether2/3/4/5 are always configured as part of the LAN bridge.
4. wifi1 is the 5GHz radio.
5. wifi2 is the 2.4GHz radio.
6. WiFi APs configured with security.authentication-types=wpa2-psk,wpa3-psk
7. WiFi APs configured with channel.skip-dfs-channels=10min-cac

## How to Use:
1. Create the script in System>Scripts>New and give it a name.  Paste the script into the "Source" section.
2. Modify the "DEFAULT ACCESS POINT SSIDs AND PASSWORDS" at the top of the script.  These are what you want your default SSID and passwords to be for your 5GHz and 2.4GHz radios when in AP mode.
3. Save the script by clicking "Apply" then "OK."
4. Open the terminal and run "/system script run YOUR_SCRIPT_NAME_HERE".
5. The script will prompt you to select the interface you want to become the WAN.
- WARNING: ENSURE YOU ARE NOT CURRENTLY CONNECTED TO THE ROUTER USING THAT INTERFACE OR YOU WILL LOSE CONNECTION!
6. If you select ether1 it will automatically configure it as WAN and set wifi1/wifi2 as access points.
7. If you select wifi1/wifi2 it will scan for available networks to select to and guide you through the connection process.

## To-Do:
1. Improve cross-platform reliability by creating variables for the WAN ethernet port and wifi1/wifi2.
