#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then echo 'Jalankan dengan sudo/root.' >&2; exit 1; fi
if [ -f /etc/debian_version ]; then :; else echo 'Script ini ditujukan untuk Debian.' >&2; exit 1; fi
if [ -f /var/lib/os-hardening-native-lab/installed ]; then echo 'Lab sudah disiapkan. Gunakan snapshot atau reset-lab.sh jika ingin mengulang.'; exit 0; fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openssh-server vsftpd nginx php-fpm php-mysql mariadb-server mariadb-client ufw sudo cron curl lsof net-tools
mkdir -p /var/lib/os-hardening-native-lab /opt/os-hardening-lab/backdoor

# Training accounts. These are intentionally weak starting conditions for the disposable VM.
echo 'root:RootStart!2026' | chpasswd
for pair in 'ubuntu:UbuntuLab!2026' 'guest:GuestStart!2026' 'anonymous:AnonStart!2026'; do
  user="${pair%%:*}"; pass="${pair#*:}"
  id "$user" >/dev/null 2>&1 || useradd -m -s /bin/bash "$user"
  echo "$user:$pass" | chpasswd
done
usermod -aG sudo ubuntu || true

# Save the intentionally vulnerable starting hashes so the progress checker can
# tell whether the participant actually changed the training passwords.
getent shadow root ubuntu guest anonymous > /var/lib/os-hardening-native-lab/baseline-shadow

auto_backup() { cp -a "$1" "$1.lab-before" 2>/dev/null || true; }
auto_backup /etc/ssh/sshd_config
auto_backup /etc/vsftpd.conf
[ -f /etc/nginx/sites-available/default ] && auto_backup /etc/nginx/sites-available/default
[ -f /etc/mysql/mariadb.conf.d/50-server.cnf ] && auto_backup /etc/mysql/mariadb.conf.d/50-server.cnf

cat > /etc/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
AllowUsers ubuntu guest root
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

cat > /etc/vsftpd.conf <<'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
xferlog_enable=YES
EOF

cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.php index.html;
    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
EOF

# Deliberately disable the global access log in the starting state. The
# participant must explicitly restore /var/log/nginx/access.log.
sed -i -E 's@^\s*access_log\s+.*;\s*$@    access_log off;@' /etc/nginx/nginx.conf
# Deliberately expose the Nginx version in the starting state. Remove any
# previous lab setting first so an old VM cannot make this check pass early.
sed -i '/server_tokens[[:space:]]/d' /etc/nginx/nginx.conf
sed -i '/^[[:space:]]*http[[:space:]]*{/a\    server_tokens on;' /etc/nginx/nginx.conf
printf 'on\n' > /var/lib/os-hardening-native-lab/baseline-nginx-server-tokens

cat > /var/www/html/index.php <<'EOF'
<?php
$mysqli = new mysqli('127.0.0.1', 'labapp', 'LabApp!2026', 'labdb');
$id = $_GET['id'] ?? '1';
$result = $mysqli->query("SELECT '$id' AS requested_id");
if ($result) { $row = $result->fetch_assoc(); echo '<h1>Training app</h1><p>ID: '.$row['requested_id'].'</p>'; }
if (isset($_GET['page'])) { include $_GET['page']; }
if (isset($_GET['cmd'])) { system($_GET['cmd']); }
EOF

cat > /etc/sudoers.d/anonymous-lab <<'EOF'
anonymous ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/anonymous-lab
cat > /etc/os-hardening-lab-secret.conf <<'EOF'
DB_PASSWORD=LabApp!2026
TRAINING_NOTE=This file should be readable only by root
EOF
chmod 644 /etc/os-hardening-lab-secret.conf

cat > /etc/systemd/system/os-hardening-lab-backdoor.service <<'EOF'
[Unit]
Description=Training backdoor service
[Service]
Type=simple
ExecStart=/bin/sh -c 'while true; do sleep 3600; done'
[Install]
WantedBy=multi-user.target
EOF
cat > /opt/os-hardening-lab/backdoor/maintenance.sh <<'EOF'
#!/bin/sh
echo training-backdoor
EOF
chmod 777 /opt/os-hardening-lab/backdoor
chmod 4755 /opt/os-hardening-lab/backdoor/maintenance.sh
systemctl daemon-reload
systemctl enable --now os-hardening-lab-backdoor.service

# Initialize application database and deliberately bind publicly; participant must fix this.
mariadb -uroot <<'SQL'
CREATE DATABASE IF NOT EXISTS labdb;
CREATE USER IF NOT EXISTS 'labapp'@'localhost' IDENTIFIED BY 'LabApp!2026';
GRANT ALL ON labdb.* TO 'labapp'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MariaRoot!2026';
FLUSH PRIVILEGES;
SQL
cnf=/etc/mysql/mariadb.conf.d/50-server.cnf
if grep -q '^bind-address' "$cnf"; then sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$cnf"; else printf '\nbind-address = 0.0.0.0\n' >> "$cnf"; fi
php_ini=$(php --ini 2>/dev/null | awk -F': ' '/Loaded Configuration File/{print $2}')
[ -n "$php_ini" ] && sed -i -E 's/^display_errors\s*=.*/display_errors = On/; s/^expose_php\s*=.*/expose_php = On/' "$php_ini" || true
systemctl restart ssh vsftpd nginx mariadb
ufw --force disable || true

touch /var/lib/os-hardening-native-lab/installed
echo 'Lab native berhasil disiapkan. Jalankan: sudo ./check-progress.sh'
