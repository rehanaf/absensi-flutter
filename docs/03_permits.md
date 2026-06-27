# Izin, Sakit, & Cuti (Permits)

## 1. Mengajukan Izin (User)
* **Endpoint:** `/permits`
* **Method:** `POST`
* **Auth Required:** Yes
* **Format:** `multipart/form-data` (Jika ada lampiran)
* **Payload:** `start_date`, `end_date`, `type` (izin/sakit/cuti), `reason`, `attachment` (file opsional).

## 2. Manajemen Izin (Admin)
Endpoint ini dilindungi oleh middleware `role:admin`. Hanya Admin yang bisa mengakses.
Admin dapat melihat daftar izin, membuat izin secara manual, mengedit, hingga menghapus data izin.

* **Endpoint:** `/admin/permits`
* **Method:** `GET` | `POST` | `PUT /{id}` | `DELETE /{id}`

**Payload POST/PUT:**
```json
{
    "user_id": 1,
    "start_date": "2026-06-25",
    "end_date": "2026-06-26",
    "type": "sakit",
    "reason": "Sakit perut",
    "status": "approved"
}
```
*(Khusus untuk PUT, Admin bisa saja hanya mengirim `{"status": "approved"}` jika hanya ingin mengubah status).*
