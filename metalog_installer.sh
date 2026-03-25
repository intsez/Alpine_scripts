#!/bin/sh
#This script installs and configures metalog, a flexible logging system daemon (syslogd/klogd)

# Color definitions for output
GREEN='\033[0;32m'
RESET='\033[0m'

# Run the script as a root
if [ "$(id -u)" -ne 0 ]; then
	echo
	echo -e "${RED}Sorry, you need to run this script as a root.${RESET}"
	echo
exit 1
fi

# Uncomment lines starting with #http or #https to enable community/edge repos
sed -i 's/^#http/http/g' /etc/apk/repositories

# 2. Update repository index and install metalog
echo -e "${GREEN}Updating index and installing metalog...${RESET}"
apk update
apk add metalog

# 3. Check and create log directories
echo
echo -e "${GREEN}Preparing log directories...${RESET}"
for dir in /var/log/firewall /var/log/ssh /var/log/kernel; do
    if [ ! -d "$dir" ]; then
        echo "Creating $dir..."
        mkdir -p "$dir"
        chmod 750 "$dir"
    else
        echo "Directory $dir already exists, skipping..."
    fi
done

# 4. Update metalog.conf with advanced filtering (REMOVED showcount)
tee -a /etc/metalog.conf > /dev/null <<EOF

# --- Custom Security Filters ---

# Dedicated Firewall logging (Netfilter/awall)
Firewall :
  regex    = "Netfilter|DROPPED|REJECTED"
  logdir   = "/var/log/firewall"

# Dedicated SSH logging
SSH Server :
  facility = "authpriv"
  logdir   = "/var/log/ssh"

# Catch-all for important kernel events
Kernel :
  facility = "kern"
  logdir   = "/var/log/kernel"
EOF


# 5. Enable and start metalog service using OpenRC
echo
echo -e "${GREEN}Enabling metalog service...${RESET}"
rc-update add metalog default
rc-service metalog restart

# 6. Persistence check for Alpine Linux (Diskless mode)
if mount | grep -q "on / type tmpfs"; then
    echo -e "${GREEN}Diskless mode detected. Committing package and config...${RESET}"
    # Ensure the new config is tracked by LBU
    lbu add /etc/metalog.conf
    lbu commit -d
fi
echo
echo -e "${GREEN}Metalog configuration complete!${RESET}"
echo -e "Check logs here:"
echo -e "Firewall: /var/log/firewall/current"
echo -e "SSH:      /var/log/ssh/current"
echo -e "Kernel:   /var/log/kernel/current"
