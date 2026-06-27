# Pengaturan Global & Form (Public)

Endpoint ini bersifat publik (tidak memerlukan Token/Login) dan biasanya dipanggil sesaat sebelum halaman Login atau saat halaman Register/Lengkapi Profil dirender di aplikasi Flutter.

## 1. Get Pengaturan Aplikasi (Settings)
Mengembalikan struktur pengaturan aplikasi (seperti nama aplikasi, URL logo, apakah wajib *Face Recognition* atau tidak). Berguna bagi *Front-End* untuk menyesuaikan tampilan aplikasi secara dinamis.
* **Endpoint:** `/settings`
* **Method:** `GET`
* **Auth Required:** No

## 2. Get Form Fields
Mengembalikan *array* struktur *field* dinamis yang harus dirender di layar (misal: Textbox "Alamat Orang Tua").
* **Endpoint:** `/form-fields`
* **Method:** `GET`
* **Auth Required:** No
