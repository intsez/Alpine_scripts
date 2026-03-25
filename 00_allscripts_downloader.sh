#!/bin/sh
# This script allows you to download all the scripts that will help you secure your Alpine Linux system.

# GitHub Base URL - ensure this points to your REAL raw repository path
GH_RAW="https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/"

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# 1. Root check
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${RED}Error: You must run this script as root.${RESET}\n"
    exit 1
fi

# 2. Check and install wget if missing
echo -e "\n${GREEN}Checking dependencies...${RESET}"
if command -v wget >/dev/null 2>&1; then
    echo -e "wget is already installed."
else
    echo -e "wget not found. ${YELLOW}Installing...${RESET}"
    apk update && apk add wget
fi

# 3. Download scripts
echo
echo -e "${GREEN}Downloading security suite from GitHub...${RESET}"

# Array of scripts to download
SCRIPTS="awall_installer.sh metalog_installer.sh sysctl_hardening.sh"

for script in $SCRIPTS; do
    echo -ne "Fetching $script... "
    # Pobieramy plik
    wget -q "$GH_RAW/$script" -O "$script"
    
    # Sprawdzamy czy plik istnieje i nie jest pusty
    if [ ! -s "$script" ]; then
        echo -e "${RED}FAILED${RESET}"
        echo -e "Check if this URL is correct: ${YELLOW}$GH_RAW/$script${RESET}"
        exit 1
    else
        echo -e "${GREEN}OK${RESET}"
        chmod +x "$script"
    fi
done


# 4. Sequential execution
echo -e "\n${GREEN}Starting installation sequence...${RESET}"

# We run them one by one. If one fails, the chain stops.
./awall_installer.sh && \
./metalog_installer.sh && \
./sysctl_hardening.sh

# 5. Final check
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}All security modules installed successfully.${RESET}"
	echo
else
    echo -e "\n${RED}Installation failed during one of the stages.${RESET}"
    exit 1
fi
