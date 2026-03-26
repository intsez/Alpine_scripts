## Key Purpose 

These scripts automate the installation of essential software and security hardening on Alpine Linux systems. They offer a fast, lightweight, and robust way to set up a secure environment.

## Usage

Simply download and execute the selected script (all default variables are set at the beginning of each file), e.g.:

```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/00_all_scripts_downloader.sh
chmod +x 00_all_scripts_downloader.sh
./00_all_scripts_downloader.sh
```


## Scripts overview

`00_all_scripts_downloader.sh` - All-in-one installer for web server security and hardening.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/00_all_scripts_downloader.sh
chmod +x 00_all_scripts_downloader.sh
./00_all_scripts_downloader.sh
```
---

`awall_installer.sh` - installs Awall, doas (for passwordless root access), and the OpenSSH server; configures SSH access and opens ports for HTTP(S), DNS, and NTP.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/awall_installer.sh
chmod +x awall_installer.sh
./awall_installer.sh
```
---

`metalog_installer.sh` - installs and configures Metalog, a flexible logging replacement for syslogd/klogd.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/metalog_installer.sh
chmod +x metalog_installer.sh
./metalog_installer.sh
```
---

`sysctl_hardening.sh` - reduces attack surface by optimizing TCP/memory and, among other improvements, strengthening protection against SYN flood (DoS/DDoS) attacks.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/sysctl_hardening.sh
chmod +x sysctl_hardening.sh
./sysctl_hardening.sh
```
---

## LICENSE

GPL v3.0
