#!/usr/bin/env bash
set -u

pass=0
total=12
json=0
watch=0
for arg in "$@"; do case "$arg" in --json) json=1;; --watch) watch=1;; esac; done

check_once() {
  pass=0
  declare -a names statuses details
  add() { names+=("$1"); statuses+=("$2"); details+=("$3"); [ "$2" = OK ] && pass=$((pass+1)); }

  ssh_ok=NO
  grep -Eq '^\s*PermitRootLogin\s+no\s*$' /etc/ssh/sshd_config 2>/dev/null && grep -Eq '^\s*AllowUsers\s+.*ubuntu' /etc/ssh/sshd_config 2>/dev/null && grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null && ssh_ok=OK
  add 'SSH hardening' "$ssh_ok" 'root login off; users restricted; guest key-only'

  ftp_ok=NO; grep -Eq '^\s*anonymous_enable\s*=\s*NO\s*$' /etc/vsftpd.conf 2>/dev/null && ftp_ok=OK
  add 'FTP anonymous disabled' "$ftp_ok" 'vsftpd anonymous_enable=NO'

  nginxv=NO; command -v nginx >/dev/null 2>&1 && [ "$(cat /var/lib/os-hardening-native-lab/baseline-nginx-server-tokens 2>/dev/null)" = on ] && nginx -T 2>/dev/null | grep -Eq '^\s*server_tokens\s+off\s*;' && nginxv=OK
  add 'Nginx version hidden' "$nginxv" 'server_tokens off'

  access=NO; nginx -T 2>/dev/null | grep -Eq 'access_log\s+/var/log/nginx/access\.log' && access=OK
  add 'Nginx access log' "$access" '/var/log/nginx/access.log'

  phpini=$(php --ini 2>/dev/null | awk -F': ' '/Loaded Configuration File/{print $2}')
  ph=NO
  [ -n "$phpini" ] && grep -Eq '^\s*display_errors\s*=\s*Off' "$phpini" && grep -Eq '^\s*log_errors\s*=\s*On' "$phpini" && ! grep -RqsE 'system\s*\(|shell_exec\s*\(|eval\s*\(' /var/www --include='*.php' 2>/dev/null && ph=OK
  add 'PHP basic hardening' "$ph" 'errors off; errors logged; dangerous calls removed'

  uf=NO; command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi 'Status: active' && uf=OK
  add 'UFW active' "$uf" 'firewall active; verify only required ports are allowed'

  sud=OK; grep -RqsE '^\s*anonymous\s+.*NOPASSWD\s*:' /etc/sudoers /etc/sudoers.d 2>/dev/null && sud=NO
  add 'Anonymous sudo rule removed' "$sud" 'no NOPASSWD rule for anonymous'

  bd=OK; [ -e /etc/systemd/system/os-hardening-lab-backdoor.service ] && bd=NO; [ -e /opt/os-hardening-lab/backdoor/maintenance.sh ] && bd=NO
  add 'Training backdoor removed' "$bd" 'service and backdoor file absent'

  perm=NO
  if [ ! -e /etc/os-hardening-lab-secret.conf ] || { [ "$(stat -c '%U:%a' /etc/os-hardening-lab-secret.conf 2>/dev/null)" = root:600 ]; }; then perm=OK; fi
  add 'Critical file permissions' "$perm" 'secret config root-only'

  db=NO; grep -RqsE '^\s*bind-address\s*=\s*127\.0\.0\.1\s*$' /etc/mysql 2>/dev/null && ! ss -ltn 2>/dev/null | grep -qE '0\.0\.0\.0:3306|:::3306' && db=OK
  add 'MariaDB local-only' "$db" 'bind-address=127.0.0.1'

  pw=NO
  if mariadb -uroot -p4nT1pwn3dserv3r -e 'SELECT 1' >/dev/null 2>&1; then pw=OK; fi
  add 'MariaDB root password changed' "$pw" 'module password accepted'

  users=NO
  baseline=/var/lib/os-hardening-native-lab/baseline-shadow
  if [ -s "$baseline" ]; then
    changed=0
    for u in root guest anonymous; do
      before=$(awk -F: -v user="$u" '$1==user{print $2}' "$baseline")
      after=$(getent shadow "$u" 2>/dev/null | cut -d: -f2)
      [ -n "$before" ] && [ -n "$after" ] && [ "$before" != "$after" ] && changed=$((changed+1))
    done
    [ "$changed" -eq 3 ] && users=OK
  fi
  add 'Training user passwords set' "$users" 'root, guest, anonymous have password hashes'

  pct=$((pass * 100 / total))
  if [ "$json" -eq 1 ]; then
    printf '{"passed":%d,"total":%d,"percent":%d,"checks":[' "$pass" "$total" "$pct"
    for i in "${!names[@]}"; do [ "$i" -gt 0 ] && printf ','; printf '{"name":"%s","status":"%s","detail":"%s"}' "${names[$i]}" "${statuses[$i]}" "${details[$i]}"; done
    printf ']}\n'
  else
    printf '\nOS & Web Hardening Native Lab\n'
    printf '%s\n' '----------------------------------------'
    for i in "${!names[@]}"; do printf '[%-2s] %-34s %s\n' "${statuses[$i]}" "${names[$i]}" "${details[$i]}"; done
    printf '%s\n' '----------------------------------------'
    printf 'Progress: %d/%d checks passed (%d%%)\n' "$pass" "$total" "$pct"
    printf 'Pemeriksa hanya membaca kondisi; tidak memperbaiki sistem.\n\n'
  fi
}

if [ "$watch" -eq 1 ]; then while true; do clear; check_once; sleep 5; done; else check_once; fi
