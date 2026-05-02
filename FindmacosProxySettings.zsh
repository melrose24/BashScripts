#!/bin/zsh

# Get the current proxy settings
proxy_settings=$(scutil --proxy)

# Print the proxy settings
echo "$proxy_settings"