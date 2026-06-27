# Admin: Pengaturan & Laporan

Endpoint ini dilindungi oleh middleware `role:admin`. Hanya *User* dengan *Role* Administrator yang bisa mengakses.

## 1. Pengaturan Aplikasi (Settings)
Digunakan untuk mengkonfigurasi kebijakan aplikasi (misal: "Wajib Foto", "Boleh Ubah Nama", dll).

* **Endpoint Get:** `GET /admin/settings` (Mengambil struktur settings lengkap dengan label dan tipe)
* **Endpoint Update:** `POST /admin/settings`
* **Payload:** 
```json
{
    "settings": {
        "user_can_edit_name": "1", 
        "require_face": "0"
    }
}
```

## 2. Manajemen Absensi Manual (CRUD)
Admin dapat melihat, menambah, mengubah, dan menghapus data absensi karyawan/siswa. Sangat berguna jika karyawan lupa absen atau terjadi kesalahan *check-in/out*.

* **Endpoint:** `/admin/attendances`
* **Method:** `GET` | `POST` | `PUT /{id}` | `DELETE /{id}`
* **Payload POST/PUT:** `user_id`, `date`, `check_in` (format: H:i:s), `check_out`, `status`, `is_late`, `late_minutes`.

## 3. Laporan & Ekspor Absensi

### 3.1 Pratinjau Laporan (JSON)
Digunakan oleh *Front-End* admin untuk melihat dan memfilter tabel laporan absensi sebelum diekspor.
* **Endpoint:** `GET /admin/reports/attendances`
* **Query Params:**
  * `start_date` (required, format YYYY-MM-DD)
  * `end_date` (required, format YYYY-MM-DD)
* **Response:** Mengembalikan *array* data JSON `attendances` yang sudah difilter rentang tanggal tersebut.

### 3.2 Unduh File Laporan (Excel / PDF)
* **Endpoint Export File:** `GET /admin/reports/export`
  * **Query Params:** 
    * `start_date` (required)
    * `end_date` (required)
    * `format` (required: `excel` atau `pdf`)
    * `group_id` (opsional)
