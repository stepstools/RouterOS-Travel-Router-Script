# --- DEFAULT ACCESS POINT SSIDs AND PASSWORDS ---
:local apSSID5G "Change_Me_5G_SSID"
:local apSSID2G "Change_Me_2G_SSID"
:local apPassword "Super_Secret_Password"
:local bridgeName "bridge"

:put "----- TRAVEL ROUTER MODE SELECTOR SCRIPT -----"
:put "Select the desired WAN interface:"
:put "1 - ether1 | 2 - wifi1 (5GHz) | 3 - wifi2 (2.4GHz)"
:local userInput; /terminal { :set userInput [inkey] }

# MODE 1
:if ($userInput = 49) do={
    # Configure WiFi Radios as Access Points
    /interface wifi set [find name=wifi1] configuration.mode=ap configuration.ssid=$apSSID5G security.passphrase=$apPassword security.authentication-types=wpa2-psk,wpa3-psk channel.skip-dfs-channels=10min-cac disabled=no
    /interface wifi set [find name=wifi2] configuration.mode=ap configuration.ssid=$apSSID2G security.passphrase=$apPassword security.authentication-types=wpa2-psk,wpa3-psk channel.skip-dfs-channels=10min-cac disabled=no
    
    # Configure Bridge
    /interface bridge port remove [find interface=ether1]
    :foreach p in={ "ether2";"ether3";"ether4";"ether5";"wifi1";"wifi2" } do={ :do { /interface bridge port add bridge=$bridgeName interface=$p } on-error={} }
    
    # Configure DHCP Client
    /ip dhcp-client remove [find interface=wifi1]
    /ip dhcp-client remove [find interface=wifi2]
    :if ([:len [/ip dhcp-client find interface=ether1]] = 0) do={
        /ip dhcp-client add interface=ether1 disabled=no
    } else={
        /ip dhcp-client enable [find interface=ether1]
    }
    
    # Configure WAN/LAN Interfaces
    /interface list member remove [find list=WAN]
    /interface list member add list=WAN interface=ether1
    :do { /interface list member add list=LAN interface=$bridgeName } on-error={}
    :put ">>> Ethernet WAN Configuration Complete!"
}

# MODE 2 & 3
:if ($userInput = 50 || $userInput = 51) do={
    :local wanInt "wifi1"; :local lanInt "wifi2"; :local lanSSID $apSSID2G
    :if ($userInput = 51) do={ :set wanInt "wifi2"; :set lanInt "wifi1"; :set lanSSID $apSSID5G }

    # Configure LAN WiFi Radio as Access Point
    /interface wifi set [find name=$lanInt] configuration.mode=ap configuration.ssid=$lanSSID security.passphrase=$apPassword security.authentication-types=wpa2-psk,wpa3-psk channel.skip-dfs-channels=10min-cac disabled=no

    # Remove WAN WiFi From Bridge Before Connecting
    /interface bridge port remove [find interface=$wanInt]

    # Configure Bridge
    :foreach p in={ "ether1";"ether2";"ether3";"ether4";"ether5";$lanInt } do={ :do { /interface bridge port add bridge=$bridgeName interface=$p } on-error={} }

    # Configure WAN/LAN Interfaces
    /interface list member remove [find list=WAN]
    /interface list member add list=WAN interface=$wanInt
    :do { /interface list member add list=LAN interface=$bridgeName } on-error={}

    # Configure WAN WiFi Radio as Station
    /interface wifi set [find name=$wanInt] configuration.mode=station channel.skip-dfs-channels=10min-cac disabled=no
    /interface wifi unset [find name=$wanInt] security.authentication-types
    
    # Search for Networks to Connect To
    :put "Scanning for available networks... (10 Seconds)"
    :local results [/interface/wifi/scan $wanInt duration=10s as-value]
    :local ssidList [:toarray ""]

    :put "----- Available Networks -----"
    :foreach r in=$results do={
        :local sid ($r->"ssid")
        
        # Only Show Unique SSIDs Longer Than 1 Char
        :if ([:len $sid] > 1 && [:find $ssidList $sid] = [:nothing]) do={
            :set ssidList ($ssidList , $sid)
            :put "[ $[:len $ssidList] ] - $sid ($($r->"signal") dBm)"
        }
    }

    :if ([:len $ssidList] = 0) do={
        :error "No networks found!"
    }
    
    :put "Select Network #:"
    :local index (([/terminal inkey] - 49))

    :if ($index >= 0 && $index < [:len $ssidList]) do={
        :local targetSSID ($ssidList->$index)
        :local targetPass [/terminal/ask prompt="Password (Blank for Open Network): "]
        
        :put ">>> Connecting to $targetSSID..."
        
        # Connect to WiFi Network
        /interface wifi set [find name=$wanInt] configuration.ssid=$targetSSID
        :if ([:len $targetPass] > 0) do={
            /interface wifi set [find name=$wanInt] security.passphrase=$targetPass
        } else={
            /interface wifi unset [find name=$wanInt] security.passphrase
        }
        
        # Configure DHCP Client
        /ip dhcp-client remove [find interface=ether1]
        /ip dhcp-client remove [find interface=$lanInt]
        :if ([:len [/ip dhcp-client find interface=$wanInt]] = 0) do={
            /ip dhcp-client add interface=$wanInt disabled=no
        } else={
            /ip dhcp-client enable [find interface=$wanInt]
        }
        
        # Wait for DHCP Client to Get Address
        :put ">>> Requesting IP address from $targetSSID..."
        :local counter 0
        :local timeout 60
        :local gotIP false

        :while ($counter < $timeout) do={
            :local dhcpStatus [/ip dhcp-client get [find interface=$wanInt] status]
            :if ($dhcpStatus = "bound") do={
                :set gotIP true
                :local currentIP [/ip dhcp-client get [find interface=$wanInt] address]
                :put ">>> DHCP Status: $dhcpStatus ($counter/$timeout)..."
                :put ">>> Success! Connected with IP: $currentIP"
                # Break the loop
                :set counter $timeout
            } else={
                :set counter ($counter + 1)
                :put ">>> DHCP Status: $dhcpStatus ($counter/$timeout)..."
                :delay 1s
            }
        }

        :if ($gotIP = false) do={
            :put "!!! Warning: DHCP failed to get an IP within $timeout seconds."
            :error "!!! Check password and captive portal."
        }
        
        :put ">>> WiFi WAN Configuration Complete!"
        
    } else={ :error "Invalid network selection." }
}
