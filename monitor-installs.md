#!/bin/zsh

echo "=== macOS Background Installation Monitor ==="
echo "Press Ctrl+C to stop\n"

# Function to check for installations
check_installs() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local found_activity=false
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║ Scan Time: $timestamp"
    echo "╚════════════════════════════════════════════════════════════════╝"
    
    # Check for installer processes
    local installers=$(ps aux | grep -iE "install" | grep -v grep | grep -v "monitor-installs")
    if [[ -n "$installers" ]]; then
        echo "\n🔧 INSTALLER PROCESSES FOUND:"
        echo "$installers"
        found_activity=true
    fi
    
    # Check for software update processes
    local updates=$(ps aux | grep -iE "softwareupdate|MobileSoftwareUpdate|system_installd" | grep -v grep)
    if [[ -n "$updates" ]]; then
        echo "\n📦 SOFTWARE UPDATE PROCESSES:"
        echo "$updates"
        found_activity=true
    fi
    
    # Check for App Store activity
    local appstore=$(ps aux | grep -iE "storedownloadd|appstoreagent|commerce" | grep -v grep)
    if [[ -n "$appstore" ]]; then
        echo "\n🏪 APP STORE ACTIVITY:"
        echo "$appstore"
        found_activity=true
    fi
    
    # Check for package files being accessed
    local packages=$(lsof 2>/dev/null | grep -iE "\.pkg|\.mpkg|PackageKit" | head -10)
    if [[ -n "$packages" ]]; then
        echo "\n📄 ACTIVE PACKAGE FILES:"
        echo "$packages"
        found_activity=true
    fi
    
    # Check for processes in uninterruptible sleep (blocking I/O)
    local blocked=$(ps aux | awk '$8 ~ /D/ {print $2, $8, $11, $12, $13}')
    if [[ -n "$blocked" ]]; then
        echo "\n⏸️  PROCESSES IN UNINTERRUPTIBLE SLEEP (may be waiting on install):"
        echo "PID  STATE COMMAND"
        echo "$blocked"
        found_activity=true
    fi
    
    # Check for MDM/Management tools
    local mdm=$(ps aux | grep -iE "jamf|munki|mosyle|kandji|octory|mdmclient" | grep -v grep)
    if [[ -n "$mdm" ]]; then
        echo "\n🔐 MDM/MANAGEMENT PROCESSES:"
        echo "$mdm"
        found_activity=true
    fi
    
    # Check files being written to system directories
    local writing=$(lsof +D /Applications 2>/dev/null | grep -v "Safari\|Chrome\|Finder\|SystemUIServer" | head -5)
    if [[ -n "$writing" ]]; then
        echo "\n✍️  FILES BEING WRITTEN TO /Applications:"
        echo "$writing"
        found_activity=true
    fi
    
    # Check for homebrew
    local brew=$(ps aux | grep -iE "brew" | grep -v grep)
    if [[ -n "$brew" ]]; then
        echo "\n🍺 HOMEBREW ACTIVITY:"
        echo "$brew"
        found_activity=true
    fi
    
    if [[ "$found_activity" == false ]]; then
        echo "\n✅ No installation activity detected"
    fi
    
    echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
}

# Main monitoring loop
while true; do
    clear
    check_installs
    echo "Refreshing in 5 seconds... (Ctrl+C to stop)"
    sleep 5
done