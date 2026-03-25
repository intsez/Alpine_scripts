## Usage

Just download and execute selected script :
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/00_all_scripts_downloader.sh
chmod +x 00_all_scripts_downloader.sh
./00_all_scripts_downloader.sh
```
Script functions:

**`awall_installer.sh`** - script installs Alpine Wall (firewall),doas (works like sudo and allows a user with privileges to log in as root without a password), openssh-server and configures SSH access, opens ports for HTTP, HTTPS, DNS, NTP services.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/awall_installer.sh
chmod +x awall_installer.sh
./awall_installer.sh
```

**`metalog_installer.sh`** - script installs and configures metalog, a flexible logging system daemon (syslogd/klogd)
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/metalog_installer.sh
chmod +x metalog_installer.sh
./metalog_installer.sh
```

**`sysctl_hardening.sh`** - script reduces the attack surface by optimizing TCP packets, memory utilization, and strengthening protection against SYN flood attacks (DoS/DDoS).
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/sysctl_hardening.sh
chmod +x sysctl_hardening.sh
./sysctl_hardening.sh
```
All default variables are set at the beginning of each script.


## LICENSE

GPL v3.0
