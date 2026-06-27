# Fitur Wali Murid (Parent)

Endpoint ini dilindungi oleh middleware `role:parent`. Hanya *User* dengan peran wali murid yang bisa mengakses.

## 1. Pemantauan Absensi Anak
Wali murid bisa melihat riwayat kehadiran (absen masuk/pulang), jam keterlambatan, hingga status kehadiran anak-anak mereka.
* **Endpoint:** `/parent/children/attendances`
* **Method:** `GET`
* **Auth Required:** Yes (Role `parent`)
