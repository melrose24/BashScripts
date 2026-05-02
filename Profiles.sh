#!/bin/zsh

# --- Management & Profile Audit Script ---
# Purpose: Identify MDM status and list all Configuration Profiles
# Requirement: Must be run as root (or via Jamf Policy)

# Set path for standard utilities
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

# Get current user for context
CURRENT_USER=$(/usr/bin/stat -f%Su /dev/console)
echo "--------------------------------------------------------------"
echo "Device Management Audit for: $(scutil --get ComputerName)"
echo "Current Logged-in User: $CURRENT_USER"
echo "Date: $(date)"
echo "--------------------------------------------------------------"

# 1. Check MDM Enrollment Status
echo "### 1. MDM ENROLLMENT STATUS ###"
MDM_STATUS=$(/usr/bin/profiles status -type enrollment)
echo "$MDM_STATUS"

# 2. Check Jamf Binary Status
echo -e "\n### 2. JAMF FRAMEWORK STATUS ###"
if [[ -f "/usr/local/bin/jamf" ]]; then
    JAMF_VER=$(/usr/local/bin/jamf about)
    echo "Jamf Binary: Installed ($JAMF_VER)"
else
    echo "Jamf Binary: NOT FOUND"
fi

# 3. List All Installed Configuration Profiles
echo -e "\n### 3. INSTALLED CONFIGURATION PROFILES ###"
# 'profiles -P' lists all profiles. We'll parse it for readability.
PROFILES_RAW=$(/usr/bin/profiles -P)

if [[ -z "$PROFILES_RAW" || "$PROFILES_RAW" == *"There are no configuration profiles installed"* ]]; then
    echo "No configuration profiles found."
else
    # Output headers for a clean look
    printf "%-40s %-30s %s\n" "PROFILE NAME" "ORGANIZATION" "IDENTIFIER"
    printf "%-40s %-30s %s\n" "------------" "------------" "----------"

    # Use awk to parse the profiles output
    # Note: 'profiles -L' or '-P' output can be messy; this extracts key fields
    /usr/bin/profiles -P | awk '
    /attribute: name:/ {name=$NF} 
    /attribute: organization:/ {org=$NF} 
    /attribute: identifier:/ {print name, org, $NF}
    ' | while read -r p_name p_org p_id; do
        printf "%-40s %-30s %s\n" "$p_name" "$p_org" "$p_id"
    done
    
    # Simple summary if awk parsing is too specific for your version
    echo -e "\nTotal Profiles Count: $(echo "$PROFILES_RAW" | grep -c "attribute: identifier:")"
fi

echo "--------------------------------------------------------------"