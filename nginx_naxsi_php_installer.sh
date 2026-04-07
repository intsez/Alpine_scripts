#!/bin/sh

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: You must run this script as root.${RESET}"
    exit 1
fi

# Enable community and edge repositories
sed -i 's/^#http/http/g' /etc/apk/repositories

# 1. UPDATE AND INSTALL PACKAGES
apk update
apk add nginx nginx-mod-http-naxsi wget unzip fail2ban ipset metalog logrotate \
    php-fpm php-opcache php-session php-json php-openssl \
    php-mbstring php-phar php-curl php-dom php-xml php-xmlwriter php-tokenizer

# 2. LOGGING SETUP (Metalog - KISS version)
# [CHANGE]: Removed custom metalog.conf to use package defaults and avoid syntax errors.
# [CHANGE]: Pre-create /var/log/messages, which is the standard log file for Alpine's metalog.
mkdir -p /var/log/everything
touch /var/log/messages
touch /var/log/nginx/error.log

rc-update add metalog default
rc-service metalog restart

# 3. PHP-FPM DETECTION & CONFIG
installed_php=$(ls /etc/init.d/php-fpm* | xargs basename)
justVer=$(echo ${installed_php} | grep -Eo '[0-9]+$')

cat > /etc/php${justVer}/php-fpm.d/www.conf << EOL
[www]
user = nginx
group = nginx
listen = /run/${installed_php}/php-fpm.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOL

# 4. NGINX & NAXSI SETUP
cat > /etc/nginx/http.d/default.conf << 'EOL'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
        SecRulesEnabled;
        DeniedUrl "/naxsi_error.html";
        CheckRule "$SQL >= 8" BLOCK;
        CheckRule "$RFI >= 8" BLOCK;
        CheckRule "$TRAVERSAL >= 4" BLOCK;
        CheckRule "$EVADE >= 4" BLOCK;
        CheckRule "$XSS >= 8" BLOCK;
    }

    location ~ \.php$ {
        SecRulesEnabled;
        DeniedUrl "/naxsi_error.html";
        CheckRule "$SQL >= 8" BLOCK;
        CheckRule "$RFI >= 8" BLOCK;
        CheckRule "$TRAVERSAL >= 4" BLOCK;
        CheckRule "$EVADE >= 4" BLOCK;
        CheckRule "$XSS >= 8" BLOCK;
        fastcgi_pass unix:/run/PHP_FPM_SOCK/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL
sed -i "s|/run/PHP_FPM_SOCK/|/run/${installed_php}/|g" /etc/nginx/http.d/default.conf

# 5. NAXSI RULES DOWNLOAD
echo -n "Downloading NAXSI rules... "
mkdir -p /etc/nginx/naxsi
cd /etc/nginx/naxsi || exit 1
urls="https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/10000000_scanner.rules
https://raw.githubusercontent.com/nbs-system/naxsi-rules/refs/heads/master/Scanner.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/20000000_web_security.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/30000000_wordpress.rules
https://raw.githubusercontent.com/nbs-system/naxsi-rules/refs/heads/master/wordpress.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/40000000_php_security.rules
https://raw.githubusercontent.com/wargio/naxsi/refs/heads/main/naxsi_rules/blocking/50000000_sql_injection.rules"

for url in $urls; do wget -q "$url"; done
echo -e "${GREEN}Done.${RESET}"

if ! grep -q "naxsi_core.rules" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    include /etc/nginx/naxsi_core.rules;\n    include /etc/nginx/naxsi/*.rules;' /etc/nginx/nginx.conf
fi

# 6. FAIL2BAN INTEGRATION
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

# 7. WEBSITE CONTENT
mkdir -p /var/www/html
if [ -z "$(ls -A /var/www/html)" ]; then
    cd /var/www/html && wget https://html5up.net/aerial/download -O aerial.zip && \
    unzip -q aerial.zip && rm aerial.zip
    echo "<html><body><h1>Access Denied</h1></body></html>" > naxsi_error.html
    chown -R nginx:nginx /var/www/html
fi

# 8. MODE DETECTION & PERSISTENCE
rc-update add nginx default
rc-update add ${installed_php} default
rc-update add fail2ban default

ROOT_TYPE=$(mount | grep ' / ' | awk '{print $5}')
if [ "$ROOT_TYPE" = "tmpfs" ] || [ "$ROOT_TYPE" = "rootfs" ]; then
    echo "Diskless mode detected. Persisting configuration..."
    lbu add /etc/nginx /etc/php* /etc/fail2ban /etc/logrotate.d
    lbu commit -d
fi

# 9. START SERVICES
rc-service ${installed_php} restart
rc-service nginx restart
rc-service fail2ban restart
echo
echo -e "${GREEN}Installation finished.${RESET}"
echo
