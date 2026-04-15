#!/bin/sh

# WordPress installer for Alpine Linux on a LEMP stack with NAXSI and security tools to provide a hardened CMS environment (fail2ban, metalog, logrotate, ipsec...)"

# Emergency exit function
exit_clean() {
    # Restore terminal settings and reset colors
    stty sane
    printf "\033[0m" 
    echo -e "\n${RED}Interrupted. Exiting...${NC}"
    exit 1
}

# Colors
RED='\033[41;37m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
	echo
    echo -e "${RED}Error: You must run this script as root.${RESET}"
    echo
    exit 1
fi

echo -e "${BLUE}================================================================${RESET}"
echo -e "${CYAN}      WordPress Installer for Alpine Linux (LEMP Stack)${RESET}"
echo -e "${GREEN}    Hardened CMS Environment with NAXSI, Fail2ban & More${RESET}"
echo -e "${BLUE}================================================================${RESET}"

# Enable community repositories
sed -i 's/^#http/http/g' /etc/apk/repositories

echo 
echo -e "${GREEN}Updating repositories and verifying software. Please wait...${RESET}"

# Time synchronization
ntpd -d -q -n -p pool.ntp.org 2>/dev/null || { echo -e "${RED}\nTime synchronization failure. Process aborted. Please re-run the script${RESET}"; exit 1; }

# Update package lists
apk update > /dev/null

# Find and set the latest available PHP 8.x version
PHP_LATEST_VER=$(apk search -q php8* | grep -E '^php8[0-9]-fpm' | cut -d'-' -f1 | sed 's/php//' | sort -n | tail -1)

# Initial server software verification (Informational)

echo
echo "Server software: "
echo "-----------------"

MISSING_APPS=""

# Helper to align status column (at 18th character)
print_status() {
    local label=$1
    local status=$2
    if [ "$status" = "OK" ]; then
        printf " %-18s ${GREEN}%s${RESET}\n" "$label:" "OK"
    else
        printf " %-18s ${RED}%s${RESET}\n" "$label:" "NONE"
    fi
}

# --- Nginx + NAXSI---
if [ ! -f /usr/sbin/nginx ]; then 
    print_status "nginx" "NONE"; MISSING_APPS="$MISSING_APPS nginx nginx-mod-http-naxsi"
else 
    print_status "nginx" "OK"
fi

# --- MariaDB ---
if [ ! -f /usr/bin/mariadb ]; then 
    print_status "mariadb" "NONE"; MISSING_APPS="$MISSING_APPS mariadb mariadb-client"
else 
    print_status "mariadb" "OK"
fi

# --- PHP CLI ---
PHP_BIN=$(ls /usr/bin/php8* 2>/dev/null | head -n 1)
if [ -z "$PHP_BIN" ]; then
    print_status "php" "NONE"
else
    print_status "php" "OK"
fi

# --- PHP-FPM and modules ---
if [ -z "$PHP_BIN" ]; then
    print_status "php-fpm" "NONE"
    # Fallback to the latest detected version if PHP is missing
    PHP_VER="$PHP_LATEST_VER"
    MISSING_APPS="$MISSING_APPS php$PHP_VER-fpm php$PHP_VER-common"
else
    PHP_VER=$(basename $PHP_BIN | sed 's/php//')
    print_status "php-fpm" "OK"
fi

# --- Fail2ban ---
if [ ! -d /etc/fail2ban ]; then 
    print_status "fail2ban" "NONE"; MISSING_APPS="$MISSING_APPS fail2ban"
else 
    print_status "fail2ban" "OK"
fi

# --- ipset ---
if [ ! -f /usr/sbin/ipset ]; then 
    print_status "ipset" "NONE"; MISSING_APPS="$MISSING_APPS ipset"
else 
    print_status "ipset" "OK"
fi

# -- logrotate
if [ ! -f /usr/sbin/logrotate ]; then 
    print_status "logrotate" "NONE"; MISSING_APPS="$MISSING_APPS logrotate"
else 
    print_status "logrotate" "OK"
fi

# -- metalog
if [ ! -f /usr/sbin/metalog ]; then 
    print_status "metalog" "NONE"; MISSING_APPS="$MISSING_APPS metalog"
else 
    print_status "metalog" "OK"
fi

# --- Additional utilities (curl, openssl, unzip, ca-certificates) ---
for app in curl openssl unzip ca-certificates; do
    if [ "$app" = "ca-certificates" ]; then
        # Verify ca-certificates via directory or package manager
        if [ ! -d /usr/share/ca-certificates ] && [ ! -f /usr/sbin/update-ca-certificates ]; then
            print_status "$app" "NONE"; MISSING_APPS="$MISSING_APPS $app"
        else
            print_status "$app" "OK"
        fi
    else
        if [ ! -f /usr/bin/$app ]; then
            print_status "$app" "NONE"; MISSING_APPS="$MISSING_APPS $app"
        else
            print_status "$app" "OK"
        fi
    fi
done

# Remove leading/trailing whitespace from the list
MISSING_APPS=$(echo $MISSING_APPS | xargs)

# Prompt for user configuration 
get_password() {
    local prompt="$1"
    local password=""
    printf "%s" "$prompt"
    stty -echo
    while IFS= read -r -n1 char; do
        [ "$char" = "" ] && break
        if [ "$char" = "$(printf '\177')" ]; then
            if [ -n "$password" ]; then password="${password%?}"; printf "\b \b"; fi
        else password="$password$char"; printf "*"; fi
    done
    stty echo
    printf "\n"
    eval "$2=\"$password\""
}
echo
# Conditional backup of wordpress.conf
NGINX_CONF="/etc/nginx/http.d/wordpress.conf"
if [ -f "$NGINX_CONF" ]; then
    DATE_SUFFIX=$(date +%d-%m-%y_%H.%M)
    cp "$NGINX_CONF" "${NGINX_CONF%.conf}.conf.bck-$DATE_SUFFIX"
	echo -e " ${RED}Backup created /etc/nginx/http.d/wordpress.conf.bck-$DATE_SUFFIX${RESET}"
fi

# Backup existing fail2ban jail configuration
FAIL2BAN_CONF="/etc/fail2ban/jail.local"
if [ -f "$FAIL2BAN_CONF" ]; then
    DATE_SUFFIX=$(date +%d-%m-%y_%H.%M)
    cp "$FAIL2BAN_CONF" "${FAIL2BAN_CONF%.conf}.bck-$DATE_SUFFIX"
    echo -e " ${RED}Backup created /etc/fail2ban/jail.local.bck-$DATE_SUFFIX${RESET}"
fi

# Notify about missing software
if [ -n "$MISSING_APPS" ]; then
    echo -e " ${RED}Missing software will be installed automatically.${RESET}"
fi
echo
echo -e "${GREEN}--- WordPress setup: provide administrative credentials ---${RESET}"
while [ -z "$ADMIN_USER" ]; do read -p " Login:  " ADMIN_USER; done
while true; do
    read -p " E-mail: " ADMIN_EMAIL
    case "$ADMIN_EMAIL" in *@*.*) break ;; *) echo -e "${RED} Error: Invalid email!${RESET}" ;; esac
done

while true; do
    get_password " Enter password:  " PASS1
    get_password " Repeat password: " PASS2
    [ "$PASS1" = "$PASS2" ] && [ -n "$PASS1" ] && ADMIN_PASS="$PASS1" && break
    echo -e "${RED} Password mismatch. Try again.${RESET}"
done

echo -e "\n${GREEN}--- Path verification. Directory listing for /var/www:---${RESET}"
ls -F /var/www 2>/dev/null || echo -e " ${RED}The /var/www directory is empty.${RESET}"
while true; do
    read -p " Provide absolute path for WordPress: " WP_PATH
    [ -z "$WP_PATH" ] && continue
    
    echo -ne " Is this the correct path for WP: ${GREEN}${WP_PATH}${RESET} [y/n]?: "
    read CONFIRM
    
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        break
    fi
done

while true; do
    # Get server IP address
    DETECTED_IP=$(ip -o -4 addr list | grep -v '127.0.0.1' | awk '{print $4}' | cut -d/ -f1 | head -n 1)
    
    # Show confirmation prompt with colored IP
    echo -ne " Is this the correct WP host: ${GREEN}${DETECTED_IP}${RESET} [y/n]?: "
    read CONFIRM2

    if [ "$CONFIRM2" = "y" ] || [ "$CONFIRM2" = "Y" ]; then
        CURRENT_IP=$DETECTED_IP
        break
    else
        read -p " Enter server address/domain: " CURRENT_IP
        # check for user input and prompt for confirmation
        if [ -n "$CURRENT_IP" ]; then
            echo -ne " Is ${GREEN}${CURRENT_IP}${RESET} correct? (y/n): "
            read CONFIRM3
            [ "$CONFIRM3" = "y" ] || [ "$CONFIRM3" = "Y" ] && break
        fi
    fi
done

# ===============================================
#   Trigger install process after any key press
# ===============================================
echo
echo -e "${RED}Ready to install. Press any key to continue or Ctrl+C to cancel.${RESET}"
	read -n1 -r -p ""
		
# Install missing dependencies
echo
if [ -n "$MISSING_APPS" ]; then
    echo -e "${GREEN}Installing software ...${RESET}"
    apk add $MISSING_APPS
fi

# Installing missing PHP modules
apk add php$PHP_VER-mysqli php$PHP_VER-phar php$PHP_VER-mbstring \
        php$PHP_VER-tokenizer php$PHP_VER-ctype php$PHP_VER-curl \
        php$PHP_VER-dom php$PHP_VER-xml php$PHP_VER-openssl php$PHP_VER-zlib \
        php$PHP_VER-exif php$PHP_VER-fileinfo php$PHP_VER-pecl-imagick \
        php$PHP_VER-zip php$PHP_VER-gd php$PHP_VER-iconv php$PHP_VER-intl

# Create PHP symlink to fix WP-CLI environment error
[ ! -f /usr/bin/php ] && ln -sf /usr/bin/php$PHP_VER /usr/bin/php

# Update memory_limit in php.ini
PHP_INI="/etc/php$PHP_VER/php.ini"
if [ -f "$PHP_INI" ]; then
    sed -i 's/memory_limit = .*/memory_limit = 256M/' $PHP_INI
	# disable sendmail to prevent 'connection refused' errors (no local SMTP server)
	sed -i 's/^[; ]*sendmail_path[[:space:]]*=.*/sendmail_path = \/bin\/true/' /etc/php${PHP_VER}/php.ini
fi

# Adjust /tmp space for extraction
mount -o remount,size=512M /tmp 2>/dev/null

# Configure PHP-FPM socket and permissions (fixes 502 Bad Gateway)
FPM_CONF="/etc/php$PHP_VER/php-fpm.d/www.conf"
if [ -f "$FPM_CONF" ]; then
    # Switch PHP-FPM from port to unix socket
    sed -i "s|listen = .*|listen = /run/php-fpm$PHP_VER/php-fpm.sock|" $FPM_CONF
    # Set socket ownership to nginx
    sed -i "s|;listen.owner = .*|listen.owner = nginx|" $FPM_CONF
    sed -i "s|;listen.group = .*|listen.group = nginx|" $FPM_CONF
    sed -i "s|;listen.mode = .*|listen.mode = 0660|" $FPM_CONF
fi

# Ensure socket directory exists
mkdir -p /run/php-fpm$PHP_VER
chown nginx:nginx /run/php-fpm$PHP_VER

rc-service php-fpm$PHP_VER restart
rc-service nginx restart

# Initialize database
[ ! -d "/var/lib/mysql/mysql" ] && mariadb-install-db --user=mysql --datadir=/var/lib/mysql
rc-service mariadb start 2>/dev/null || /etc/init.d/mariadb start

DB_NAME="wp_db_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
DB_PREF="wp_pref_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
DB_USER="wp_u_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
DB_PASS="$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)"

mariadb -e "CREATE DATABASE $DB_NAME; CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

# WordPress Nginx server block setup
# Conditional backup of default.conf
BCK_DEFCONF="/etc/nginx/http.d/default.conf"
if [ -f "$BCK_DEFCONF" ]; then
    DATE_SUFFIX=$(date +%d-%m-%y_%H.%M)
    cp "$BCK_DEFCONF" "${BCK_DEFCONF%.conf}.conf.bck-$DATE_SUFFIX"
    echo
	echo -e " ${RED}Backup created /etc/nginx/http.d/default.conf.bck-$DATE_SUFFIX${RESET}"
fi
rm -rf /etc/nginx/http.d/default.conf
mkdir -p "$WP_PATH"
cat << EOL > /etc/nginx/http.d/wordpress.conf
server {
    listen 80 default_server;
    root ${WP_PATH};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args; 
		
	# Enable/Disable learning mode
		LearningMode;
	
	# Enable/Disable rules
	#	SecRulesEnabled;
	 
	# Change this to webpage error
        DeniedUrl "/naxsi_error.html";
        
        CheckRule "\$SQL >= 8" BLOCK;
        CheckRule "\$RFI >= 8" BLOCK;
        CheckRule "\$TRAVERSAL >= 4" BLOCK;
        CheckRule "\$EVADE >= 4" BLOCK;
        CheckRule "\$XSS >= 8" BLOCK;
    }

    location ~ \.php$ {
		
	# Enable/Disable learning mode
		LearningMode;
	
	# Enable/Disable rules
	#	SecRulesEnabled;
        
        # Change this to webpage error
        DeniedUrl "/naxsi_error.html";
        
        CheckRule "\$SQL >= 8" BLOCK;
        CheckRule "\$RFI >= 8" BLOCK;
        CheckRule "\$TRAVERSAL >= 4" BLOCK;
        CheckRule "\$EVADE >= 4" BLOCK;
        CheckRule "\$XSS >= 8" BLOCK;
        
        fastcgi_pass unix:/run/php-fpm${PHP_VER}/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL


# Downlaod NAXSI rules
echo
echo -ne "Downloading NAXSI rules... "
mkdir -p /etc/nginx/naxsi
cd /etc/nginx/naxsi || exit 1

# Status Flag
SUCCESS=true
urls="https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/10000000_scanner.rules
https://raw.githubusercontent.com/nbs-system/naxsi-rules/refs/heads/master/Scanner.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/20000000_web_security.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/30000000_wordpress.rules
https://raw.githubusercontent.com/nbs-system/naxsi-rules/refs/heads/master/wordpress.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/40000000_php_security.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/50000000_sql_injection.rules"

for url in $urls; do 
    if ! curl -fsSLO "$url"; then
        SUCCESS=false
        break
         # Break loop on first error (optional)
    fi
done

if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}Done${RESET}."
else
    echo -e "${RED}Failed${RESET}."
   
fi
echo
if ! grep -q "naxsi_core.rules" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    include /etc/nginx/naxsi_core.rules;\n    include /etc/nginx/naxsi/*.rules;' /etc/nginx/nginx.conf
fi

# Integrate Fail2ban with Nginx and NAXSI
cat > /etc/fail2ban/filter.d/naxsi.conf << EOL
[Definition]
failregex = NAXSI_FMT: ip=<HOST>.*&config=block
EOL

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Add enabled line under [sshd] header
sed -i '/^\[sshd\]/a enabled = true' /etc/fail2ban/jail.local
# Update logpath specifically for sshd
sed -i '/^\[sshd\]/,/backend/ s|^[# ]*logpath = .*|logpath = /var/log/messages|' /etc/fail2ban/jail.local

# [CHANGE]: Using /var/log/messages as the most reliable default path for metalog.
cat >> /etc/fail2ban/jail.local << EOL
[naxsi]
enabled = true
port = http,https
filter = naxsi
logpath = /var/log/nginx/error.log
maxretry = 2
bantime = 3600
EOL

# WordPress installation using WP-CLI
if [ ! -f /usr/local/bin/wp ]; then
    curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

cd "$WP_PATH"
wp core download --allow-root

wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbprefix=$DB_PREF --allow-root
wp core install --url="$CURRENT_IP" --title="WP Alpine" --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASS" --admin_email="$ADMIN_EMAIL" --allow-root

# Resolve 502 Bad Gateway by using correct PHP-FPM service
rc-service php-fpm$PHP_VER restart
rc-service nginx restart

# Custom NAXSI error page
[ ! -f "$WP_PATH/wp-content/naxsi_error.html" ] && echo "<html><body><h1>Access Denied</h1></body></html>" > "$WP_PATH/wp-content/naxsi_error.html"

# Set correct permissions for WordPress directory
chown -R nginx:nginx ${WP_PATH}

# MODE DETECTION & PERSISTENCE
rc-update add nginx
rc-update add php-fpm${PHP_VER}
rc-update add fail2ban
rc-update add mariadb 

# Handle Diskless/Data mode and LBU persistence
if mount | grep -qE " / (tmpfs|rootfs)"; then
    lbu add /etc/nginx
    lbu add /etc/php${PHP_VER}
  	lbu add /etc/fail2ban
	lbu add /var/lib/fail2ban
    lbu commit -d
fi

while [ "$SECMDB" != "y" ] && [ "$SECMDB" != "n" ]; do
    echo
    printf "${GREEN}--- Enable MariaDB security hardening${RESET} [y/n]?: "
    read SECMDB
done

if [ "$SECMDB" = "y" ]; then
    echo ""
    mysql_secure_installation
    echo ""
fi
echo
echo -e "${GREEN} NAXSI is running in ${CYAN}Learning mode ${RED}(non-blocking)${RESET} \n   > /etc/nginx/http.d/wordpress.conf <"
echo -e "${GREEN} Admin dashboard:${RESET} ${CYAN}http://$CURRENT_IP/wp-admin${RESET}"
echo
echo -e "${GREEN}--- SETUP COMPLETE ---${RESET}"
echo
exit 0
