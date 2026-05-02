#!/bin/zsh

# Check if Remote Desktop is enabled
if sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -status | grep -q "Remote Management is currently enabled"; then
  echo "<result>Enabled</result>"
else
  echo "<result>Disabled</result>"
fi