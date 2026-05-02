#!/bin/bash

echo "=== Cache Audit Report ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo ""

echo "--- Top Cache Offenders (~/Library/Caches) ---"
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -20

echo ""
echo "--- /tmp usage ---"
du -sh /tmp/* 2>/dev/null | sort -rh | head -10

echo ""
echo "--- System Caches (/Library/Caches) ---"
du -sh /Library/Caches/* 2>/dev/null | sort -rh | head -10

echo ""
echo "--- Total ~/Library/Caches ---"
du -sh ~/Library/Caches 2>/dev/null

echo ""
echo "--- Disk Space Summary ---"
df -h /