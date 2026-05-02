#!/bin/bash
###############################################################
# Intune Remediation - Remediation Script
# Purpose: Remove targeted app caches to reclaim disk space
# Run As:  Logged-in User
# Version: 1.0
#
# Targets (safe to delete — all self-heal on next app launch):
#   - Homebrew       (~4.1G)  Re-downloads on next brew install/update
#   - Microsoft Edge (~1.6G)  Rebuilds on next browse session
#   - Google Chrome  (~1.5G)  Rebuilds on next browse session
#   - Spotify        (~1.3G)  Re-streams on next playback
#   - VSCode ShipIt  (~876M)  Re-downloads on next update cycle
#   - Movavi         (~250M)  Render previews only — no projects lost
#   - Zoom           (~36M)   UI assets re-download on next launch
###############################################################

LOG_TAG="[Intune-CacheCleanup]"
TOTAL_BEFORE=0
TOTAL_AFTER=0

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG $1"
}

remove_cache() {
    local LABEL="$1"
    local CACHE_PATH="$2"

    if [ -d "$CACHE_PATH" ]; then
        SIZE_BEFORE=$(du -sm "$CACHE_PATH" 2>/dev/null | awk '{print $1}')
        TOTAL_BEFORE=$((TOTAL_BEFORE + SIZE_BEFORE))

        rm -rf "$CACHE_PATH" 2>/dev/null

        if [ ! -d "$CACHE_PATH" ]; then
            log "SUCCESS: Cleared $LABEL (${SIZE_BEFORE}MB freed)"
        else
            SIZE_AFTER=$(du -sm "$CACHE_PATH" 2>/dev/null | awk '{print $1}')
            TOTAL_AFTER=$((TOTAL_AFTER + SIZE_AFTER))
            log "PARTIAL: $LABEL partially cleared (${SIZE_BEFORE}MB → ${SIZE_AFTER}MB)"
        fi
    else
        log "SKIP: $LABEL — path not found, nothing to clear"
    fi
}

###############################################################
# Main
###############################################################

log "=== Starting Targeted Cache Cleanup ==="
log "User: $(whoami)"
log "Host: $(hostname)"

# --- Homebrew ---
remove_cache "Homebrew" "$HOME/Library/Caches/Homebrew"

# --- Microsoft Edge ---
remove_cache "Microsoft Edge" "$HOME/Library/Caches/Microsoft Edge"

# --- Google Chrome ---
remove_cache "Google Chrome" "$HOME/Library/Caches/Google"

# --- Spotify ---
remove_cache "Spotify" "$HOME/Library/Caches/com.spotify.client"

# --- VSCode ShipIt (updater cache) ---
remove_cache "VSCode ShipIt" "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"

# --- Movavi (render/preview cache) ---
remove_cache "Movavi" "$HOME/Library/Caches/Movavi"

# --- Zoom ---
remove_cache "Zoom" "$HOME/Library/Caches/us.zoom.xos"

###############################################################
# Summary
###############################################################

RECLAIMED=$((TOTAL_BEFORE - TOTAL_AFTER))

log "=== Cleanup Complete ==="
log "Total Before : ${TOTAL_BEFORE}MB"
log "Total After  : ${TOTAL_AFTER}MB"
log "Total Reclaimed : ${RECLAIMED}MB"

exit 0
