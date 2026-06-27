# Admin: Hak Akses (Roles & Permissions)

Sistem ini mendukung pengaturan hak akses (*Role-Based Access Control*) dinamis. Setiap *Role* (Jabatan) bisa memiliki beberapa *Permission* (Izin Spesifik). Endpoint admin kini dilindungi berdasarkan *Permission*, bukan lagi secara statis mengecek "Apakah role-nya admin?".

Misalnya, rute untuk mengelola absensi membutuhkan hak akses `manage-attendances`. Jika Admin memberikan hak akses ini ke Role `guru`, maka `guru` tersebut bisa mengakses rute tersebut.

## 1. Manajemen Roles
Endpoint ini dilindungi oleh permission `manage-roles`.
* **Endpoint:** `/admin/roles`
* **Method:** `GET` | `POST` | `PUT` | `DELETE`

**Response GET:** Mengembalikan daftar peran beserta seluruh *permissions* yang dimilikinya, dan juga *array* `available_permissions` (seluruh *permission* yang ada di database).

## 2. Sync Permissions (Mengaitkan Hak Akses ke Role)
Digunakan untuk memasang atau mencabut hak-hak akses spesifik ke dalam sebuah *Role*. Semua *permission_ids* yang dikirim akan me-replace hak akses lama.
* **Endpoint:** `/admin/roles/{id}/sync-permissions`
* **Method:** `POST`
* **Payload:**
```json
{
    "permission_ids": [1, 2, 5]
}
```

## Daftar Permissions Default
1. `manage-users`: Mengelola Karyawan & User
2. `manage-roles`: Mengelola Role & Hak Akses
3. `manage-groups`: Mengelola Grup / Divisi
4. `manage-schedules`: Mengelola Jadwal Absensi
5. `manage-locations`: Mengelola Lokasi Cabang
6. `manage-attendances`: Mengelola Data Absensi Manual
7. `manage-settings`: Mengubah Pengaturan Sistem
8. `approve-permits`: Menyetujui & Mengelola Izin
9. `view-reports`: Melihat & Mengunduh Laporan
