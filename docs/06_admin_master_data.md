# Admin: Master Data (Cabang, Jadwal, Grup)

Endpoint ini dilindungi oleh middleware `role:admin`. Hanya *User* dengan *Role* Administrator yang bisa mengakses.

## 1. Manajemen Cabang (Locations)
- **Endpoint:** `/admin/locations`
- **Method:** `GET` | `POST` | `PUT` | `DELETE`

**Payload POST/PUT:**
```json
{
    "name": "Kantor Cabang Jakarta",
    "latitude": "-6.200000",
    "longitude": "106.816666",
    "radius": 50
}
```

## 2. Jadwal Absensi Horizontal (Schedules)
Satu baris jadwal mengelola 7 hari sekaligus dalam format kolom horizontal.
- **Endpoint:** `/admin/schedules`
- **Method:** `GET` | `POST` | `PUT` | `DELETE`

**Payload POST/PUT (Format 7-Hari):**
```json
{
    "group_id": null,
    "monday_in": "07:00:00",
    "monday_out": "16:00:00",
    "tuesday_in": "07:00:00",
    "tuesday_out": "16:00:00",
    "wednesday_in": "07:00:00",
    "wednesday_out": "16:00:00",
    "thursday_in": "07:00:00",
    "thursday_out": "16:00:00",
    "friday_in": "07:00:00",
    "friday_out": "16:00:00",
    "saturday_in": null,
    "saturday_out": null,
    "sunday_in": null,
    "sunday_out": null,
    "is_flexible": false
}
```

## 3. Manajemen Groups (Grup/Divisi/Kelas)
* **Endpoint:** `/admin/groups`
* **Method:** `GET` | `POST` | `PUT` | `DELETE`

### 3.1 Menambahkan User ke Grup
* **Endpoint:** `/admin/groups/{id}/attach-user`
* **Method:** `POST`
* **Payload:** `{"user_id": 1}`

### 3.2 Menghapus User dari Grup
* **Endpoint:** `/admin/groups/{id}/detach-user`
* **Method:** `POST`
* **Payload:** `{"user_id": 1}`

## 4. Manajemen Custom Fields
Untuk menambahkan bidang khusus di form pendaftaran/profil (misalnya: "Alamat Orang Tua").
* **Endpoint:** `/admin/form-fields`
* **Method:** `GET` | `POST` | `PUT` | `DELETE`
* **Payload POST:** `field_label`, `field_name`, `field_type`, `is_required`, `is_editable`

## 5. Manajemen Roles (Peran Akses)
Digunakan untuk mengelola peran akses (seperti: admin, guru, siswa, parent).
* **Endpoint:** `/admin/roles`
* **Method:** `GET` | `POST` | `PUT` | `DELETE`
