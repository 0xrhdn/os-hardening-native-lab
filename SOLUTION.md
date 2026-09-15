# Petunjuk Verifikasi Native Lab

Pemeriksa membaca konfigurasi aktual dan menampilkan kategori yang lulus. Ia tidak melakukan hardening otomatis.

Untuk SSH, periksa `/etc/ssh/sshd_config`, gunakan `sshd -t`, lalu reload service. Untuk vsftpd, ubah `anonymous_enable` menjadi `NO` dan restart service. Untuk Nginx, tambahkan `server_tokens off;`, cek `nginx -t`, dan pastikan access log berada di lokasi modul. Untuk PHP, gunakan prepared statements, output escaping, allow-list file, dan hilangkan command execution dari input pengguna; set `display_errors=Off` serta `log_errors=On`.

Untuk sudoers, gunakan `visudo` dan hapus aturan anonymous NOPASSWD. Untuk backdoor latihan, identifikasi `/etc/systemd/system/os-hardening-lab-backdoor.service` dan `/opt/os-hardening-lab/backdoor/maintenance.sh`, simpan bukti bila diperlukan, lalu disable/remove artefaknya. Untuk permission, target file rahasia latihan adalah `root:root` mode `600`. Untuk MariaDB, ubah password root menjadi `4nT1pwn3dserv3r` dan set `bind-address = 127.0.0.1`. Uji seluruh service setelah perubahan.

Jika UFW gagal pada VM karena kebijakan jaringan atau koneksi SSH, gunakan console VM, izinkan SSH sebelum enable, lalu periksa `ufw status verbose`. Jangan menjalankan setup ini pada server produksi.
