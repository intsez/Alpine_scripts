## Key Purpose 

These scripts automate the installation of essential software and security hardening on Alpine Linux systems. They offer a fast, lightweight, and robust way to set up a secure environment.

## Usage

Simply download and execute the selected script (all default variables are set at the beginning of each file), e.g.:

```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/00_all_scripts_downloader.sh
chmod +x 00_all_scripts_downloader.sh
sh 00_all_scripts_downloader.sh
```


## Scripts overview

`00_all_scripts_downloader.sh` - All-in-one installer for web server security and hardening.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/00_all_scripts_downloader.sh
chmod +x 00_all_scripts_downloader.sh
sh 00_all_scripts_downloader.sh
```
---

`awall_installer.sh` - installs Awall, doas (for passwordless root access), and the OpenSSH server; configures SSH access and opens ports for HTTP(S), DNS, and NTP.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/awall_installer.sh
chmod +x awall_installer.sh
sh awall_installer.sh
```
---

`metalog_installer.sh` - installs and configures Metalog, a flexible logging replacement for syslogd/klogd.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/metalog_installer.sh
chmod +x metalog_installer.sh
sh metalog_installer.sh
```
---

`sysctl_hardening.sh` - reduces attack surface by optimizing TCP/memory and, among other improvements, strengthening protection against SYN flood (DoS/DDoS) attacks.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/sysctl_hardening.sh
chmod +x sysctl_hardening.sh
sh sysctl_hardening.sh
```
---

`nginx_naxsi_php_installer.sh` - installs and configures Nginx with NAXSI WAF, PHP-FPM, and integrates Fail2Ban for automated blocking based on NAXSI and Metalog logs.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/nginx_naxsi_php_installer.sh
chmod +x nginx_naxsi_php_installer.sh
sh nginx_naxsi_php_installer.sh
```
---

`wordpress_installer.sh` - automated WordPress deployment on an Alpine-based LEMP stack, featuring NAXSI WAF and a hardened security suite (fail2ban, metalog, logrotate, ipset, and more). Includes optimized security rules for wp-config.php, Nginx, and system-wide hardening.
```sh
wget https://raw.githubusercontent.com/intsez/Alpine_scripts/refs/heads/main/wordpress_installer.sh
chmod +x wordpress_installer.sh
sh wordpress_installer.sh
```
---

## LICENSE

GPL v3.0
