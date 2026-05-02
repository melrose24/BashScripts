#!/usr/bin/env bash

# --- 1. Initialization & Flags ---
if [[ "$*" == *"-d"* ]] || [[ "$*" == *"-Debug"* ]]; then
    set -x
    echo "Debug mode enabled"
fi

if [ "$EUID" -ne 0 ]; then 
    echo "Please run using 'sudo $0'"
    exit 1
fi

HOSTNAME=$(scutil --get LocalHostName)
NOW=$(date +%Y-%m-%dT%H-%M-%S)
ODCFILENAME="$HOSTNAME-IntuneMacODC-$NOW.zip"

# --- 2. Directory Setup ---
if [ -d "odc" ]; then
    mv "odc" "odc_$(date +%s)"
fi
mkdir -p odc && cd odc || exit

echo "Starting diagnostic collection... this may take a few minutes."

# --- 3. System & MDM Info ---
{
    echo -e "--- OS VERSION ---\n$(sw_vers)\n"
    echo -e "--- UNAME ---\n$(uname -a)\n"
} > system_info.txt

# FIX: Modern Profile Collection
# 'profiles -xml' is deprecated; system_profiler is the reliable replacement
echo "Capturing profile data..."
profiles status > profiles_status.txt 2>/dev/null
profiles list -verbose > profiles_list_verbose.txt 2>/dev/null
system_profiler SPConfigurationProfileDataType -xml > profiles_data.xml 2>/dev/null

# Capture MDM Client State
for cmd in QueryInstalledProfiles QueryCertificates QueryDeviceInformation QueryInstalledApps QuerySecurityInfo dumpSCEPVars; do
    echo "--- $cmd ---" > "mdm_$cmd.txt"
    /usr/libexec/mdmclient "$cmd" >> "mdm_$cmd.txt" 2>/dev/null
done

# --- 4. Logs & Path Collection ---
zip_if_exists() {
    if [ -e "$1" ]; then
        # We use -q for quiet, -r for recursive
        zip -rq "$ODCFILENAME" "$1" -x "*Siri*" 2>/dev/null
    fi
}

zip_if_exists "$HOME/Library/Logs/Company Portal"
zip_if_exists "$HOME/Library/Logs/Microsoft"
zip_if_exists "/var/log"
zip_if_exists "$HOME/Library/Application Support/Microsoft/Intune/SideCar"
zip_if_exists "/Library/Logs/Microsoft/Defender"
zip_if_exists "/usr/local/jamf/bin/jamfAAD"

# --- 5. Unified System Log Extraction ---
echo "Gathering syslogs (last 30 days)..."
log show --style syslog --info --debug --last 30d \
    --predicate 'process CONTAINS "Intune" || process CONTAINS "mdm" || process CONTAINS "apsd" || process CONTAINS "downloadd"' \
    > system_mdm_logs.log 2>/dev/null

# --- 6. Software & Packaging ---
pkgutil --pkgs | sort | while read -r pkg; do
    pkgutil --pkg-info "$pkg" 2>/dev/null
    echo "----------------"
done > installed_packages.txt

# --- 7. Finalize ---
# Full System Report (XML format)
/usr/sbin/system_profiler -detailLevel mini -xml > SystemReport.spx 2>/dev/null

# Zip everything into the final archive
zip -rq "$ODCFILENAME" ./*.txt ./*.log ./*.xml ./*.spx 2>/dev/null

echo "Success! Report created: $(pwd)/$ODCFILENAME"

# Cleanup: remove temp files, keeping only the ZIP
find . -type f ! -name "*.zip" -delete

# Open folder and return
open .
cd ..