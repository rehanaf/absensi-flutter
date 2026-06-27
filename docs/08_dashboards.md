# Dashboards

Endpoint ini mengembalikan statistik ringkas untuk layar utama aplikasi setelah *login*.

## 1. Dashboard User Umum (Karyawan/Siswa)
* **Endpoint:** `/dashboard/user`
* **Method:** `GET`
* **Auth Required:** Yes (Bebas Role)

## 2. Dashboard Admin
Mengembalikan ringkasan data seperti total *user*, total hadir hari ini, persentase keterlambatan, dan jumlah izin tertunda.
* **Endpoint:** `/dashboard/admin`
* **Method:** `GET`
* **Auth Required:** Yes (Role `admin`)

## 3. Dashboard Parent (Wali Murid)
Mengembalikan ringkasan performa/kehadiran anak.
* **Endpoint:** `/dashboard/parent`
* **Method:** `GET`
* **Auth Required:** Yes (Role `parent`)
