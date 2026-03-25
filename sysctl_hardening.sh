#!/bin/sh
# This script reduces the attack surface by optimizing TCP packets, memory utilization, and strengthening protection against SYN flood attacks (DoS/DDoS).

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Configuration
GITHUB_URL="https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/sysctl"


SYSCTL_DIR="/etc/sysctl.d"
SYSCTL_FILE="$SYSCTL_DIR/99-security.conf"

# Run the script as a root
if [ "$(id -u)" -ne 0 ]; then
	echo
	echo -e "${RED}Sorry, you need to run this script as a root.${RESET}"
	echo
exit 1
fi

echo
echo -e "${GREEN}Downloading static hardening profile from GitHub...${RESET}"

# 1. Ensure directory exists and download the base template
[ ! -d "$SYSCTL_DIR" ] && mkdir -p "$SYSCTL_DIR"
wget -q "$GITHUB_URL/99-security-base.conf" -O "$SYSCTL_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download template from GitHub!${RESET}"
    exit 1
fi

# 2. Detect hardware architecture and available memory
echo
ARCH=$(uname -m)
TOTAL_RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
echo -e "${GREEN}Detected: $ARCH | RAM: ${TOTAL_RAM_MB}MB${RESET}"
# 3. Define profiles based on RAM (Logic remains local)
if [ "$TOTAL_RAM_MB" -lt 512 ]; then
    echo -e "Applying profile: ${RED}LOW-RAM (256MB)${RESET}"
    F_MAX=65535; P_MAX=32768; R_MAX=1048576; W_MAX=1048576; BACKLOG=1000; S_CONN=128
    T_RMEM="4096 8192 1048576"; T_WMEM="4096 8192 1048576"
elif [ "$TOTAL_RAM_MB" -lt 4096 ]; then
    echo -e "Applying profile: ${YELLOW}MEDIUM-RAM (1GB)${RESET}"
    F_MAX=150000; P_MAX=32768; R_MAX=4194304; W_MAX=4194304; BACKLOG=2500; S_CONN=1024
    T_RMEM="4096 87380 4194304"; T_WMEM="4096 65536 4194304"
else
    echo -e "Applying profile: ${GREEN}HIGH-PERFORMANCE (4GB+)${RESET}"
    F_MAX=2000000; [ "$ARCH" = "x86_64" ] && P_MAX=4194304 || P_MAX=32768
    R_MAX=16777216; W_MAX=16777216; BACKLOG=10000; S_CONN=4096
    T_RMEM="4096 87380 16777216"; T_WMEM="4096 65536 16777216"
fi

# 4. Inject calculated values into the downloaded file using SED
sed -i "s/^fs.file-max.*/fs.file-max = $F_MAX/" "$SYSCTL_FILE"
sed -i "s/^kernel.pid_max.*/kernel.pid_max = $P_MAX/" "$SYSCTL_FILE"
sed -i "s/^net.core.rmem_max.*/net.core.rmem_max = $R_MAX/" "$SYSCTL_FILE"
sed -i "s/^net.core.wmem_max.*/net.core.wmem_max = $W_MAX/" "$SYSCTL_FILE"
sed -i "s/^net.core.netdev_max_backlog.*/net.core.netdev_max_backlog = $BACKLOG/" "$SYSCTL_FILE"
sed -i "s/^net.core.somaxconn.*/net.core.somaxconn = $S_CONN/" "$SYSCTL_FILE"
sed -i "s/^net.ipv4.tcp_rmem.*/net.ipv4.tcp_rmem = $T_RMEM/" "$SYSCTL_FILE"
sed -i "s/^net.ipv4.tcp_wmem.*/net.ipv4.tcp_wmem = $T_WMEM/" "$SYSCTL_FILE"

# 5. Apply changes and Persistence (Alpine LBU)
sysctl -p "$SYSCTL_FILE"
if mount | grep -q "on / type tmpfs"; then
    echo -e "${GREEN}Saving to LBU...${RESET}"
    lbu commit -d
fi
echo -e "\n${GREEN}Optimization complete!${RESET}"
echo
