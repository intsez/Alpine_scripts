#!/bin/sh
# This script installs Alpine Wall (firewall),doas (works like sudo and allows a user with privileges to log in as root without a password), openssh-server and configures SSH access, opens ports for HTTP, HTTPS, DNS, NTP services.
# GitHub Base URL 
GH_RAW="https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/awall"

# Colors
GREEN='\e[32m'
RED='\e[1;31m'
RESET='\e[0m'

# Run the script as a root
if [ "$(id -u)" -ne 0 ]; then
	echo
	echo -e "${RED}Sorry, you need to run this script as a root.${RESET}"
	echo
exit 1
fi

# 1. Input Collection
while true; do
    echo
    echo -ne "Enter SSH/Admin username: ${RED}"
    read sysuser
    echo -ne "${RESET}Enter SSH port: ${RED}"
    read sshport
    echo -ne "${RESET}Allowed SSH IP/CIDR (e.g. 192.168.1.0/24): ${RED}"
    read ipaddress
    echo -ne "${RESET}Root login (no/yes/prohibit-password): ${RED}"
    read sshroot
    echo -ne "${RESET}\nConfirm data? (y/n): "
    read -n1 -r correctdata
    echo -e "\n"
    [ "$correctdata" = "y" ] && break
done

# 2. Package Installation
apk update && apk add awall iptables ip6tables wget doas openssh-server

# 3. Download and Configure Awall - JSONs
# ---------------------------------------
echo -e "${GREEN}Downloading Awall configurations from GitHub...${RESET}"

# Download main rules for Awall
wget -q "$GH_RAW/optional/main.json" -O /etc/awall/optional/main.json

# Download outgoing rules for Awall
wget -q "$GH_RAW/optional/outgoing.json" -O /etc/awall/optional/outgoing.json

# Download stealth (block ICMP - ping) rules for Awall
wget -q "$GH_RAW/optional/stealth.json" -O /etc/awall/optional/stealth.json

# Download rules for http, https
wget -q "$GH_RAW/optional/http.json" -O /etc/awall/optional/http.json

# Download rules for SSH
wget -q "$GH_RAW/optional/incoming-ssh.json" -O /etc/awall/optional/incoming-ssh.json
sed -i "s@__IP_ADDRESS__@$ipaddress@g" /etc/awall/optional/incoming-ssh.json

# Download rules for custom ports
wget -q "$GH_RAW/private/custom-ports.json" -O /etc/awall/private/custom-ports.json
sed -i "s/__SSH_PORT__/$sshport/g" /etc/awall/private/custom-ports.json

# 4. Local Services Configuration (doas & SSH)
# Configure doas
mkdir -p /etc/doas.d
echo "permit nopass $sysuser as root" > /etc/doas.d/99-wheel.conf
chmod 0400 /etc/doas.conf /etc/doas.d/*.conf

# Configure SSH
cat <<EOF > /etc/ssh/sshd_config.d/ssh.conf
Port $sshport
PermitRootLogin $sshroot
Match Address $ipaddress
PasswordAuthentication yes
    AllowUsers $sysuser
EOF

# 5. Iptables activation
modprobe ip_tables && modprobe ip6_tables
rc-update add iptables && rc-update add ip6tables
rc-service iptables start && rc-service ip6tables start

# 6. Awall Test, Enable & Activate
awall enable main incoming-ssh http outgoing stealth
awall translate --verify && awall activate -f 
echo
echo -e "${GREEN}--- Active policies ---${RESET}"
awall list

# 7. Persistence (Diskless mode)
if mount | grep -q "on / type tmpfs"; then
    echo -e "${GREEN}Saving to LBU...${RESET}"
    lbu add /etc/doas.conf
    lbu add /etc/ssh/sshd_config.d/ssh.conf
    lbu add /etc/awall
    lbu commit -d
fi
# 8. Post-installation information
echo -e "${GREEN}---${RESET}"
echo -e "INBOUND ${RED}ALLOWED${RESET}: HTTP, HTTPS, SSH for ${RED}$ipaddress${RESET} on ${RED}$sshport${RESET} port"
echo -e "OUTBAND ${RED}ALLOWED${RESET}: HTTP, HTTPS, DNS, NTP"
echo -e "ICMP (ping): ${RED}IGNORED ${RESET}"
echo
echo -e "${GREEN}Firewall modifications ${RESET}"
echo -e "  To change the SSH port or add more custom ports, modify: ${RED}/etc/awall/private/custom-ports.json${RESET}"
echo -e "  To enable SSH access for more IPs, modify: ${RED}/etc/awall/optional/incoming-ssh.json${RESET}"
echo -e "  To change the network interface, modify ${RED}/etc/awall/optional/main.json${RESET}"
echo
echo -e "${GREEN}SSH modifications ${RESET}"
echo -e "  To change SSH policies (port, users, IPs), modify: ${RED}/etc/ssh/sshd_config.d/ssh.conf${RESET}"
echo
echo -e "${GREEN}Installation complete.${RESET}"
echo
