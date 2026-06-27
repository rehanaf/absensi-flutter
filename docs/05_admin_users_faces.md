# Admin: Manajemen User & Face CRUD

Endpoint ini dilindungi oleh middleware `role:admin`. Hanya *User* dengan *Role* Administrator yang bisa mengakses.

## 1. Manajemen Users (CRUD Standard Laravel Resource)
Digunakan untuk mendaftarkan akun baru, menetapkan peran, serta mem-bypass pengaturan absensi.
* **Endpoint:** `/admin/users`
* **Method:** `GET` | `POST` | `PUT` | `DELETE`
* **Payload Penting:**
  - `role_id` (wajib)
  - `location_id` (opsional: titik cabang karyawan ini)
  - `is_location_flexible` (boolean: jika `true`, bebas absen dari mana saja)

## 2. Manajemen Face Biometrics (Reset / Set Face)
Digunakan jika karyawan berganti HP atau wajah lamanya sudah tidak sinkron. Admin dapat me-reset wajah karyawan.

### 2.1 Lihat Status Wajah Karyawan
Menampilkan daftar user dan status apakah mereka memiliki data wajah (`has_face_biometric`).
* **Endpoint:** `/admin/faces`
* **Method:** `GET`

### 2.2 Daftarkan Wajah Manual (Set Face)
Mengunggah data wajah (base64) secara manual dari sisi Admin.
* **Endpoint:** `/admin/faces/{user_id}`
* **Method:** `PUT`
* **Payload:**
```json
{
    "face_biometric": "base64encodedstring..."
}
```

### 2.3 Reset Wajah (Hapus Face)
Menghapus rekaman wajah karyawan dari server, agar mereka dapat merekam ulang dari awal di HP mereka.
* **Endpoint:** `/admin/faces/{user_id}`
* **Method:** `DELETE`
