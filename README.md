# OS Hardening Native Lab — Debian 12

Repository ini untuk **mesin latihan/VM Debian 12 yang disposable**. Script setup sengaja memasang layanan dan membuat beberapa kondisi rentan agar peserta dapat melakukan hardening manual. Script ini **bukan** untuk server produksi dan tidak boleh dijalankan pada mesin yang berisi data penting.

## Penting

`setup-lab.sh` mengubah akun, konfigurasi SSH, FTP, Nginx, PHP, MariaDB, sudoers, systemd, dan firewall. Gunakan VM baru dengan snapshot. Script tidak dirancang untuk menjaga akses SSH pada server produksi, tidak mengubah konfigurasi WireGuard, dan tidak boleh dijalankan pada mesin utama.

## Instalasi

Clone repository:

```bash
git clone https://github.com/0xrhdn/os-hardening-native-lab.git
cd os-hardening-native-lab
chmod +x setup-lab.sh check-progress.sh reset-lab.sh
```

Siapkan kondisi awal lab sebagai root:

```bash
sudo ./setup-lab.sh
```

Setelah setup selesai, buka terminal kedua atau console VM dan jalankan pemeriksa:

```bash
sudo ./check-progress.sh
```

Pemeriksa hanya membaca kondisi sistem. Ia tidak memperbaiki konfigurasi.

## Alur latihan

1. Jalankan `setup-lab.sh` pada VM Debian 12 baru.
2. Jalankan `check-progress.sh` dan simpan hasil baseline.
3. Kerjakan hardening manual dari tugas di `TASKS.md`.
4. Jalankan `sudo ./check-progress.sh` setelah setiap bagian.
5. Gunakan `SOLUTION.md` hanya untuk petunjuk verifikasi setelah mencoba sendiri.
6. Ambil snapshot setelah selesai atau hancurkan VM latihan.

## Perintah pemeriksa

```bash
sudo ./check-progress.sh          # ringkasan dan persentase
sudo ./check-progress.sh --json   # hasil ringkas dalam JSON sederhana
sudo ./check-progress.sh --watch  # cek ulang setiap 5 detik; Ctrl+C untuk berhenti
```

## Reset

Reset hanya menghapus artefak latihan yang dibuat script. Untuk hasil paling bersih, kembalikan snapshot VM. Jika tetap ingin menghapus artefak:

```bash
sudo ./reset-lab.sh
```

Password latihan di modul digunakan hanya untuk VM lab. Jangan memakai password tersebut pada sistem nyata.
