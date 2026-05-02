#!/bin/zsh

# --- 1. IDENTIFY USER & ENVIRONMENT ---
CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(dscl . -read /Users/$CURRENT_USER NFSHomeDirectory | awk '{print $2}')

# --- 2. DEFINE PATHS ---
DATE_STAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_DIR="$USER_HOME/Desktop/Support_Logs_$DATE_STAMP"
OUTPUT_FILE="$EXPORT_DIR/detailed_system_report.txt"
ZIP_FILE="$USER_HOME/Desktop/Support_Package_$(hostname)_$DATE_STAMP.zip"

# --- 3. DIRECTORY SETUP ---
mkdir -p "$EXPORT_DIR"
chown "$CURRENT_USER" "$EXPORT_DIR"

echo "Gathering Diagnostic Data... (This may take 30-60 seconds)"

# --- 4. DATA COLLECTION ---
{
    echo "======================================================================"
    echo "1. SYSTEM & HARDWARE IDENTITY"
    echo "======================================================================"
    echo "Hostname:        $(hostname)"
    echo "Model Identifier: $(sysctl -n hw.model)"
    echo "Architecture:    $(uname -m) ($(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Apple Silicon"))"
    echo "Serial Number:   $(ioreg -l | grep IOPlatformSerialNumber | awk -F'"' '{print $4}')"
    echo "macOS Version:   $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
    echo "Uptime:          $(uptime)"
    
    echo -e "\n======================================================================"
    echo "2. ACCOUNT INFORMATION"
    echo "======================================================================"
    echo "Logged-in User:  $CURRENT_USER"
    APPLE_ID=$(sudo -u "$CURRENT_USER" defaults read "$USER_HOME/Library/Preferences/MobileMeAccounts" Accounts 2>/dev/null | grep AccountID | awk '{print $3}' | tr -d '";')
    echo "Primary AppleID: ${APPLE_ID:-"None detected (User may not be signed into iCloud)"}"

    echo -e "\n======================================================================"
    echo "3. STORAGE & DISK HEALTH (Apple Silicon & Intel)"
    echo "======================================================================"
    # Check for SMART status across different controller types
    DISK_HEALTH=$(system_profiler SPStorageDataType | grep "SMART Status" | head -n 1 | awk -F: '{print $2}' | xargs)
    if [[ -z "$DISK_HEALTH" ]]; then
        # Fallback for Apple Silicon internal NVMe
        DISK_HEALTH=$(diskutil info / | grep "Smart" | awk -F: '{print $2}' | xargs)
    fi
    echo "Main Drive SMART Status: ${DISK_HEALTH:-"Not Supported (Check Privacy > Full Disk Access for MDM/Terminal)"}"
    
    # Show Disk Space
    df -h / | grep / | awk '{print "Capacity: " $2 " | Used: " $3 " | Available: " $4 " (" $5 " used)"}'

    echo -e "\n======================================================================"
    echo "4. POWER & BATTERY / UPS STATUS"
    echo "======================================================================"
    MODEL_ID=$(sysctl -n hw.model)
    if [[ "$MODEL_ID" == *Book* ]]; then
        # Laptop Logic
        BATT_CONDITION=$(system_profiler SPPowerDataType | grep "Condition" | awk -F: '{print $2}' | xargs)
        BATT_CYCLES=$(system_profiler SPPowerDataType | grep "Cycle Count" | awk -F: '{print $2}' | xargs)
        echo "Device Type:       Portable (MacBook)"
        echo "Battery Condition: ${BATT_CONDITION:-"Unknown"}"
        echo "Cycle Count:       ${BATT_CYCLES:-"Unknown"}"
    else
        # Desktop Logic + UPS Check
        echo "Device Type:       Desktop ($MODEL_ID)"
        UPS_CHECK=$(system_profiler SPPowerDataType | grep -A 10 "UPS Power" | grep "Name" | awk -F: '{print $2}' | xargs)
        if [[ -n "$UPS_CHECK" ]]; then
            echo "UPS Detected:      $UPS_CHECK"
            system_profiler SPPowerDataType | grep -A 5 "UPS Power" | grep -E "Capacity|Charging|Condition"
        else
            echo "Power Source:      Direct AC Power (No UPS detected via USB)"
        fi
    fi

    echo -e "\n======================================================================"
    echo "5. HARDWARE SPECS & PERIPHERALS"
    echo "======================================================================"
    system_profiler SPHardwareDataType SPMemoryDataType SPUSBDataType SPThunderboltDataType | grep -E "Memory:|Size:|Free:|Number of Processors:|Cores:|Device Name:|Manufacturer:|Speed:"

    echo -e "\n======================================================================"
    echo "6. SYSTEM FREEZES & SHUTDOWN EVENTS (Last 72h)"
    echo "======================================================================"
    SHUTDOWN_LOGS=$(log show --predicate 'eventMessage contains "previous shutdown cause"' --last 72h --style syslog | awk -F' ' '{print $1, $2, " - ", $10, $11, $12, $13, $14}')
    
    if [[ -z "$SHUTDOWN_LOGS" ]]; then
        echo "RESULT: No unclean shutdown events or freezes recorded in the last 72 hours."
    else
        echo "The following shutdown codes were recorded (Cause 0=Power, -128=Hardware, 3=Hard Restart):"
        echo "$SHUTDOWN_LOGS"
    fi

} > "$OUTPUT_FILE"

# --- 5. LOG FILE COLLECTION ---
LOG_DEST="$EXPORT_DIR/logs"
mkdir -p "$LOG_DEST"

# Capture Panic Logs (Critical for hardware troubleshooting)
find /Library/Logs/DiagnosticReports -name "*.panic" -exec cp {} "$LOG_DEST/" \; 2>/dev/null

# Capture User Crashes (Last 7 days)
mkdir -p "$LOG_DEST/User_Crashes"
find "$USER_HOME/Library/Logs/DiagnosticReports" -mtime -7 -exec cp {} "$LOG_DEST/User_Crashes/" \; 2>/dev/null

# Standard System Logs
cp /var/log/system.log "$LOG_DEST/" 2>/dev/null

# --- 6. COMPRESSION & CLEANUP ---
if (cd "$USER_HOME/Desktop" && zip -r "$(basename "$ZIP_FILE")" "$(basename "$EXPORT_DIR")" > /dev/null); then
    rm -rf "$EXPORT_DIR"
    chown "$CURRENT_USER" "$ZIP_FILE"
    echo "----------------------------------------------------------------"
    echo "SUCCESS: Diagnostic package created for $CURRENT_USER."
    echo "Location: $ZIP_FILE"
    echo "----------------------------------------------------------------"
else
    echo "ERROR: Zip compression failed." >&2
    exit 1
fi