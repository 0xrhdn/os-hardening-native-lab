#!/usr/bin/env bash
set -euo pipefail
[ "${EUID}" -eq 0 ] || { echo 'Jalankan dengan sudo/root.'; exit 1; }
cat <<'EOF'
Reset ini menghapus artefak yang dibuat lab:
- akun latihan anonymous, guest, ubuntu jika dibuat oleh lab
- aturan sudoers lab
- service dan file backdoor lab
- file rahasia lab
- backup konfigurasi *.lab-before tetap dipertahankan
Untuk kondisi paling bersih, kembalikan snapshot VM.
EOF
read -r -p 'Ketik RESET-LAB untuk melanjutkan: ' ans
[ "$ans" = RESET-LAB ] || { echo 'Dibatalkan.'; exit 0; }
systemctl disable --now os-hardening-lab-backdoor.service 2>/dev/null || true
rm -f /etc/systemd/system/os-hardening-lab-backdoor.service /etc/sudoers.d/anonymous-lab /etc/os-hardening-lab-secret.conf
rm -rf /opt/os-hardening-lab /var/lib/os-hardening-native-lab
systemctl daemon-reload
for u in anonymous guest; do id "$u" >/dev/null 2>&1 && userdel -r "$u" 2>/dev/null || true; done
echo 'Artefak lab dihapus. Untuk pemulihan konfigurasi lengkap, gunakan snapshot VM.'
