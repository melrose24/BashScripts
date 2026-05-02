#!/bin/zsh

# Get a list of all admin users
admin_users=$(dscl . -read /Groups/admin GroupMembership | awk '{print $NF}')

# Print the admin users
echo "Admin Accounts:"
for user in $admin_users; do
  echo "- $user"
done