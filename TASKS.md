# Tugas Native Debian 12

Jalankan pada VM Debian 12 baru setelah `sudo ./setup-lab.sh`. Kerjakan manual, lalu jalankan `sudo ./check-progress.sh`.

1. SSH: tolak root login langsung, batasi user SSH, dan buat `guest` key-only.
2. FTP: matikan anonymous login pada vsftpd.
3. Nginx: sembunyikan versi dan pastikan access log ke `/var/log/nginx/access.log`.
4. PHP: perbaiki SQL injection, XSS/output escaping, file inclusion, command execution, dan error disclosure.
5. UFW: aktifkan default deny incoming; izinkan hanya SSH, HTTP, HTTPS, dan FTP.
6. Sudoers/SUID: hapus aturan anonymous NOPASSWD dan analisis binary SUID.
7. Backdoor: identifikasi dan hapus unit systemd serta file backdoor latihan.
8. Permission: jadikan file konfigurasi rahasia hanya dapat diakses root.
9. MariaDB: ganti password root database menjadi `4nT1pwn3dserv3r` dan bind hanya ke localhost.
10. User: ubah password root, guest, dan anonymous sesuai modul latihan.

Setelah setiap bagian, pastikan service tetap berjalan dan jalankan pemeriksa progres.
