#!/bin/bash

# Function to retrieve Wi-Fi password
get_wifi_password() {
    SSID="$1"
    security find-generic-password -D "AirPort network password" -wa "$SSID"
}

# Main script starts here
echo "Searching for available Wi-Fi networks..."
# List all Wi-Fi networks
networks=$(networksetup -listpreferredwirelessnetworks en0)

echo "Available Wi-Fi networks:"
echo "$networks"

# Prompt user to enter the Wi-Fi network name (SSID)
read -p "Enter the Wi-Fi network name (SSID): " SSID

# Check if the entered SSID exists in the list
if echo "$networks" | grep -q "$SSID"; then
    echo "Fetching password for \"$SSID\"..."
    password=$(get_wifi_password "$SSID")
    if [ -n "$password" ]; then
        echo "Password found: $password"
    else
        echo "Password not found or access denied."
    fi
else
    echo "Error: \"$SSID\" not found in the list of available networks."
fi