#!/bin/bash

# Check if the script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo" 
  exit 1
fi

# Define the path to the Feedback Assistant application
FEEDBACK_ASSISTANT_PATH="/System/Library/CoreServices/Applications/Feedback Assistant.app"

# Check if Feedback Assistant exists at the specified location
if [ -d "$FEEDBACK_ASSISTANT_PATH" ]; then
    echo "Feedback Assistant found at $FEEDBACK_ASSISTANT_PATH. Removing..."
# Attempt to remove the Feedback Assistant application
    rm -rf "$FEEDBACK_ASSISTANT_PATH"
    if [ $? -eq 0 ]; then
        echo "Feedback Assistant has been successfully removed."
    else
        echo "An error occurred while trying to remove Feedback Assistant."
        exit 1
    fi
else
    echo "Feedback Assistant not found at $FEEDBACK_ASSISTANT_PATH. It may have already been removed."
fi

exit 0