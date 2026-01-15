#!/bin/zsh

# 1. Get the currently logged-in user
CURRENT_USER=$(/usr/bin/stat -f%Su /dev/console)

# 2. Check if a user is actually logged in
if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    echo "No user logged in. Exiting."
    exit 0
fi

# 3. Define the output file path on the user's desktop
OUTPUT_FILE="/Users/$CURRENT_USER/Desktop/Disk_Analysis_Report.txt"

# --- Functions ---

human_readable() {
    local bytes=$1
    if (( bytes >= 1099511627776 )); then
        echo "$((bytes / 1099511627776)).$(( (bytes % 1099511627776) * 100 / 1099511627776 )) TB"
    elif (( bytes >= 1073741824 )); then
        echo "$((bytes / 1073741824)).$(( (bytes % 1073741824) * 100 / 1073741824 )) GB"
    elif (( bytes >= 1048576 )); then
        echo "$((bytes / 1048576)).$(( (bytes % 1048576) * 100 / 1048576 )) MB"
    else
        echo "${bytes} B"
    fi
}

# 4. Redirect all output to the text file
{
    echo "Disk Space Analysis Report"
    echo "Generated on: $(date)"
    echo "User: $CURRENT_USER"
    echo "==================================="

    # --- SECTION A: HOME FOLDER ---
    SCAN_PATH_USER="/Users/$CURRENT_USER"
    TEMP_FILE_USER="/tmp/user_disk_usage_$$"

    /usr/bin/du -d 1 "$SCAN_PATH_USER" 2>/dev/null | /usr/bin/sort -rn > "$TEMP_FILE_USER"

    echo "TOP 15 LARGEST DIRECTORIES IN HOME FOLDER:"
    rank=1
    /usr/bin/head -15 "$TEMP_FILE_USER" | while IFS= read -r line; do
        size=${line%%[[:space:]]*}
        path=${line#*[[:space:]]}
        bytes=$((size * 512))
        readable=$(human_readable $bytes)
        printf "#%-2d %-10s %s\n" "$rank" "$readable" "$path"
        ((rank++))
    done
    rm -f "$TEMP_FILE_USER"

    echo ""
    echo "==================================="

    # --- SECTION B: SYSTEM FOLDERS ---
    SCAN_PATH_SYS="/"
    TEMP_FILE_SYS="/tmp/sys_disk_usage_$$"

    # Scanning root depth 1 (Applications, Library, System, Users, etc.)
    /usr/bin/du -d 1 "$SCAN_PATH_SYS" 2>/dev/null | /usr/bin/sort -rn > "$TEMP_FILE_SYS"

    echo "TOP 15 LARGEST SYSTEM DIRECTORIES (ROOT /):"
    rank=1
    /usr/bin/head -15 "$TEMP_FILE_SYS" | while IFS= read -r line; do
        size=${line%%[[:space:]]*}
        path=${line#*[[:space:]]}
        bytes=$((size * 512))
        readable=$(human_readable $bytes)
        printf "#%-2d %-10s %s\n" "$rank" "$readable" "$path"
        ((rank++))
    done
    rm -f "$TEMP_FILE_SYS"

} > "$OUTPUT_FILE"

# 5. Fix permissions so the user can open/delete the file
/usr/sbin/chown "$CURRENT_USER" "$OUTPUT_FILE"

echo "Report generated at $OUTPUT_FILE"

# Trigger a native macOS notification
# /usr/bin/osascript -e "display notification \"Disk analysis complete. Check your desktop.\" with title \"IT Support\" subtitle \"Maintenance\""