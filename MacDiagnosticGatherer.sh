#!/bin/zsh

#########################################################################################
# Enterprise Mac Diagnostic Gatherer
# Version: 2.0
# Logic: Includes error handling, trap cleanup, and environment validation.
#########################################################################################

# --- 1. PRE-FLIGHT CHECKS ---

# Ensure script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (via Jamf or sudo)."
   exit 1
fi

# Set up logging for the script's own actions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# --- 2. VARIABLES & TEMP SPACE ---

# Identify current console user
CURRENT_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name : / && ! /loginwindow/ { print $3 }')

# Setup Temporary Directory
TIMESTAMP=$(date +%Y%m%d_%H%M)
WORK_DIR="/tmp/Diagnostic_$TIMESTAMP"
FINAL_ZIP_NAME="Support_Logs_$TIMESTAMP.zip"

# Determine final destination
if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
    FINAL_DEST="/Users/$CURRENT_USER/Desktop"
else
    FINAL_DEST="/Users/Shared"
fi

# --- 3. ERROR HANDLING (TRAP) ---

# Cleanup function: deletes temp files if script exits or fails
cleanup() {
    log_message "Cleaning up temporary directory..."
    /bin/rm -rf "$WORK_DIR"
}
# Execute cleanup function on exit (successful or otherwise)
trap cleanup EXIT

# --- 4. DATA COLLECTION ---

log_message "Creating work directory at $WORK_DIR"
if ! /bin/mkdir -p "$WORK_DIR/Logs/CrashReports" 2>/dev/null; then
    log_message "FATAL ERROR: Could not create work directory."
    exit 2
fi

log_message "Gathering System Summary..."
{
    echo "--- HARDWARE ---"
    /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep -E "Model Name|Model Identifier|Serial Number"
    /usr/sbin/sysctl -n machdep.cpu.brand_string
    
    echo "\n--- STORAGE ---"
    /usr/sbin/diskutil info / | /usr/bin/grep -E "Free Space|SMART Status"
    
    echo "\n--- NETWORK ---"
    /usr/sbin/networksetup -getairportnetwork en0 2>/dev/null || echo "WiFi: Disconnected/Not found"
    /usr/sbin/ifconfig en0 | /usr/bin/grep "inet "
} > "$WORK_DIR/Summary.txt"

log_message "Copying Logs..."
# System-wide logs
/bin/cp /var/log/system.log "$WORK_DIR/Logs/" 2>/dev/null
/bin/cp /var/log/jamf.log "$WORK_DIR/Logs/" 2>/dev/null
/bin/cp /Library/Logs/DiagnosticReports/*.panic "$WORK_DIR/Logs/CrashReports/" 2>/dev/null

# User-specific logs
if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
    log_message "Collecting user-level logs for $CURRENT_USER"
    /usr/bin/rsync -am --include='*.log' --include='*/' --exclude='*' "/Users/$CURRENT_USER/Library/Logs/" "$WORK_DIR/Logs/User_Logs/" 2>/dev/null
fi

# --- 5. COMPRESSION & PERMISSIONS ---

log_message "Creating final ZIP at $FINAL_DEST"
cd "/tmp" || exit
/usr/bin/zip -r "$FINAL_DEST/$FINAL_ZIP_NAME" "Diagnostic_$TIMESTAMP" > /dev/null

if [[ -f "$FINAL_DEST/$FINAL_ZIP_NAME" ]]; then
    # Ensure the user can actually open/move the file
    /usr/sbin/chown "$CURRENT_USER" "$FINAL_DEST/$FINAL_ZIP_NAME"
    log_message "Success: $FINAL_ZIP_NAME created."
else
    log_message "ERROR: Zip file creation failed."
    exit 3
fi

# --- 6. USER NOTIFICATION (Via Jamf or AppleScript) ---

if [[ -n "$CURRENT_USER" ]]; then
    /usr/bin/osascript -e "display notification \"Support logs have been saved to your Desktop.\" with title \"IT Support\""
fi

exit 0