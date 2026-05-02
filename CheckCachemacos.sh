#!/bin/bash

THRESHOLD_MB=500
USER_CACHE=$(du -sm ~/Library/Caches 2>/dev/null | awk '{print $1}')

if [ "$USER_CACHE" -gt "$THRESHOLD_MB" ]; then
    echo "Cache size ${USER_CACHE}MB exceeds threshold. Remediation needed."
    exit 1  # Triggers remediation
else
    echo "Cache size ${USER_CACHE}MB is within limit. No action needed."
    exit 0  # No remediation needed
fi