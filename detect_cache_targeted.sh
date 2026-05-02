#!/bin/bash
###############################################################
# Intune Remediation - Detection Script
# Purpose: Detect if targeted app caches exceed threshold
# Run As:  Logged-in User
# Version: 1.0
###############################################################

THRESHOLD_MB=500
TOTAL_MB=0

CACHE_PATHS=(
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Caches/Microsoft Edge"
    "$HOME/Library/Caches/Google"
    "$HOME/Library/Caches/com.spotify.client"
    "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
    "$HOME/Library/Caches/Movavi"
    "$HOME/Library/Caches/us.zoom.xos"
)

for PATH_ITEM in "${CACHE_PATHS[@]}"; do
    if [ -d "$PATH_ITEM" ]; then
        SIZE_MB=$(du -sm "$PATH_ITEM" 2>/dev/null | awk '{print $1}')
        TOTAL_MB=$((TOTAL_MB + SIZE_MB))
    fi
done

if [ "$TOTAL_MB" -gt "$THRESHOLD_MB" ]; then
    echo "FAIL: Targeted cache total is ${TOTAL_MB}MB — exceeds ${THRESHOLD_MB}MB threshold. Remediation required."
    exit 1
else
    echo "PASS: Targeted cache total is ${TOTAL_MB}MB — within ${THRESHOLD_MB}MB threshold. No action needed."
    exit 0
fi
