#!/bin/bash

#---------------------------------------------
# CYBERPATRIOT HARDENING SCRIPT
# For Ubuntu-based images
#
# Usage:
#   1. Save this file as 'harden.sh'
#   2. Make it executable: chmod +x harden.sh
#   3. Run with root privileges: sudo ./harden.sh
#---------------------------------------------

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root."
   exit 1
fi

echo "--- Starting CyberPatriot Hardening Script ---"

# --- User and Group Management ---
# This is usually the first task.
# Be careful here! The names of bad users change every round.

echo "--> Hardening user accounts..."

# Bad users to remove. Add more as you find them.
for user in bill jenna guest student; do
    if id "$user" &>/dev/null; then
        echo "Removing user: $user"
        userdel -r "$user"
    fi
done

# Remove unnecessary users from the 'sudo' group
for group in sudo; do
    if getent group "$group" &>/dev/null; then
        echo "Checking '$group' group..."
        for user in $(getent group "$group" | cut -d: -f4 | sed 's/,/ /g'); do
            if [[ "$user" != "team" && "$user" != "root" ]]; then
                echo "Removing user '$user' from group '$group'."
                gpasswd -d "$user" "$group"
            fi
        done
    fi
done

# --- File Permissions and System Hardening ---
# This section fixes common misconfigurations.

echo "--> Fixing file permissions..."

# Find and fix world-writable files and directories.
# This command is a powerful one-liner.
echo "Searching for world-writable files and directories..."
find / -type f -perm -o+w -exec chmod o-w {} \; 2>/dev/null
find / -type d -perm -o+w -exec chmod o-w {} \; 2>/dev/null

# Secure key system files
echo "Securing critical system files..."
chmod 640 /etc/passwd /etc/group /etc/shadow
chmod 600 /etc/sudoers /etc/gshadow

# --- Service and Network Hardening ---
# Disable insecure services and configure the firewall.

echo "--> Hardening network and services..."

# List of common insecure services to disable.
# ALWAYS check to make sure these aren't needed for scoring!
services=(
    telnet.socket
    ftp.service
    nfs-server.service
    rsh.socket
    vsftpd.service
)

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "Disabling and stopping active service: $service"
        systemctl stop "$service"
        systemctl disable "$service"
    fi
done

# Enable and configure UFW (Uncomplicated Firewall)
echo "Configuring firewall with UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw enable

# --- Final Touches ---
# Clean up and provide a summary.

echo "--> Cleaning up..."

# Remove any common malware or unwanted files.
# The filename will change based on the round!
# if [ -f "/home/user/malware.sh" ]; then
#    rm /home/user/malware.sh
# fi

echo "--- Script execution complete. ---"
echo "Remember to manually check for other vulnerabilities and to verify all changes."