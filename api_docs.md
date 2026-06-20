# Dokumentasi API Absensi (White Label)

Base URL: `http://localhost/api` (Sesuaikan dengan domain Anda jika sudah di-*deploy*)  
Autentikasi: **Bearer Token** (menggunakan Laravel Sanctum)

---

## 1. Pengaturan & Dynamic Fields

Endpoint ini digunakan untuk mengambil pengaturan aplikasi (misal nama aplikasi, *identity label* seperti NIS/NIP) serta daftar *Form Fields* dinamis yang harus diisi saat registrasi atau kelengkapan profil.

* **Endpoint:** `/settings`
* **Method:** `GET`
* **Auth Required:** No

**Response (200 OK):**
```json
{
    "settings": {
        "app_name": "Absensi Sekolah",
        "identity_label": "NIS/NIP",
        "theme_color": "#3498db",
        "require_location": "1",
        "require_face": "1"
    },
    "dynamic_fields": [
        {
            "id": 1,
            "field_label": "Nama Wali Murid",
            "field_name": "nama_wali",
            "field_type": "text",
            "is_required": true
        },
        {
            "id": 2,
            "field_label": "Alamat Lengkap",
            "field_name": "alamat",
            "field_type": "textarea",
            "is_required": true
        }
    ],
    "roles": [
        {
            "name": "admin",
            "display_name": "Administrator"
        },
        {
            "name": "guru",
            "display_name": "Guru"
        },
        {
            "name": "siswa",
            "display_name": "Siswa"
        },
        {
            "name": "parent",
            "display_name": "Wali Murid"
        }
    ]
}
```

---

## 2. Autentikasi

### 2.1 Login

Melakukan login untuk mendapatkan *Access Token*.

* **Endpoint:** `/login`
* **Method:** `POST`
* **Auth Required:** No

**Request Body:**
```json
{
    "username": "ADMIN001",
    "password": "password"
}
```
*(Catatan: `login_as` bersifat opsional. Jika dikirim, backend akan memvalidasi apakah role user cocok dengan `login_as` tersebut. Jika tidak, akan mengembalikan error 401).*

**Response (200 OK):**
```json
{
    "message": "Login success",
    "access_token": "1|ZAbCdEfG...",
    "token_type": "Bearer",
    "user": {
        "id": 1,
        "role_id": 1,
        "name": "Admin Sekolah",
        "username": "ADMIN001",
        "phone_number": "081234567890",
        "can_attend": false,
        "role": {
            "id": 1,
            "name": "admin",
            "display_name": "Administrator"
        },
        "profile": null
    }
}
```

### 2.2 Get User (Me)

Mendapatkan data *User* yang sedang login beserta role, profil, dan grup (kelas/divisi) nya.

* **Endpoint:** `/user`
* **Method:** `GET`
* **Auth Required:** Yes (Bearer Token)

**Response (200 OK):**
```json
{
    "id": 1,
    "role_id": 1,
    "name": "Admin Sekolah",
    "username": "ADMIN001",
    "role": { ... },
    "profile": { ... },
    "groups": [ ... ]
}
```

### 2.3 Logout

Menghapus *token* saat ini.

* **Endpoint:** `/logout`
* **Method:** `POST`
* **Auth Required:** Yes (Bearer Token)

**Response (200 OK):**
```json
{
    "message": "Logged out successfully"
}
```

### 2.4 Pendaftaran Wajah (Register Face)

Menyimpan data biometrik wajah pengguna untuk referensi absensi harian.

* **Endpoint:** `/user/register-face`
* **Method:** `POST`
* **Auth Required:** Yes (Bearer Token)

**Request Body:**
```json
{
    "face_biometric": "[0.12, 0.44, 0.89, ...]"
}
```

**Response (200 OK):**
```json
{
    "message": "Face data registered successfully",
    "user": {
        "id": 1,
        "name": "Admin Sekolah",
        "face_biometric": "[0.12, 0.44, 0.89, ...]"
    }
}
```

---

## 3. Absensi (Attendance)

### 3.1 Check In

Mencatat absensi masuk untuk hari ini. Hanya dapat dilakukan sekali sehari.
**Penting:** Jika `require_face` aktif di Settings, gunakan `multipart/form-data` untuk mengirim file.

* **Endpoint:** `/attendance/check-in`
* **Method:** `POST`
* **Auth Required:** Yes (Bearer Token)

**Request Body (`multipart/form-data`):**
- `location_data[lat]` = `-6.2088` (Jika `require_location` aktif)
- `location_data[lng]` = `106.8456`
- `photo` = `(File Image)` (Jika `require_face` aktif)

**Response (200 OK):**
```json
{
    "message": "Check in successful",
    "attendance": {
        "id": 1,
        "user_id": 1,
        "date": "2026-06-18",
        "check_in": "08:00:00",
        "status": "hadir",
        "location_data": {
            "lat": -6.2088,
            "lng": 106.8456
        },
        "photo_path": "attendances/xyz.jpg",
        "photo_url": "http://localhost/storage/attendances/xyz.jpg",
        "updated_at": "...",
        "created_at": "..."
    }
}
```

**Error Response (400 Bad Request - Already checked in):**
```json
{
    "message": "Already checked in today"
}
```

### 3.2 Check Out

Mencatat absensi keluar untuk hari ini. Pengguna harus sudah melakukan `check-in` terlebih dahulu.

* **Endpoint:** `/attendance/check-out`
* **Method:** `POST`
* **Auth Required:** Yes (Bearer Token)

**Request Body:** Kosong

**Response (200 OK):**
```json
{
    "message": "Check out successful",
    "attendance": {
        "id": 1,
        "user_id": 1,
        "date": "2026-06-18",
        "check_in": "08:00:00",
        "check_out": "17:00:00",
        "status": "hadir"
    }
}
```

**Error Response (404 Not Found - Belum Check In):**
```json
{
    "message": "No check-in record found for today"
}
```

**Error Response (400 Bad Request - Sudah Check Out):**
```json
{
    "message": "Already checked out today"
}
```

### 3.3 History (Riwayat Absensi)

Mengambil seluruh riwayat absensi dari *User* yang sedang login, diurutkan dari tanggal paling baru.

* **Endpoint:** `/attendance/history`
* **Method:** `GET`
* **Auth Required:** Yes (Bearer Token)

**Response (200 OK):**
```json
{
    "attendances": [
        {
            "id": 1,
            "date": "2026-06-18",
            "check_in": "08:00:00",
            "check_out": "17:00:00",
            "status": "hadir",
            "photo_url": "...",
            "location_data": { "lat": -6.2088, "lng": 106.8456 }
        }
    ]
}
```

---

## 4. Admin Akses (Role: `admin`)

Endpoint ini dilindungi oleh middleware `role:admin`. Hanya *User* dengan *Role* Administrator yang bisa mengakses.

### 4.1 Lihat Seluruh Absensi Karyawan/Siswa

* **Endpoint:** `/admin/attendances`
* **Method:** `GET`
* **Auth Required:** Yes (Bearer Token + Role `admin`)

**Response (200 OK):**
```json
{
    "attendances": [
        {
            "id": 1,
            "user_id": 2,
            "date": "2026-06-18",
            "check_in": "08:00:00",
            "status": "hadir",
            "user": {
                "id": 2,
                "name": "Budi Junior"
            }
        }
    ]
}
```

### 4.2 Ubah Settings Aplikasi

* **Endpoint:** `/admin/settings`
* **Method:** `POST`
* **Auth Required:** Yes (Bearer Token + Role `admin`)

**Request Body:**
```json
{
    "settings": {
        "require_face": "0",
        "app_name": "Sistem Absensi Keren"
    }
}
```

**Response (200 OK):**
```json
{
    "message": "Settings updated successfully",
    "settings": { ... }
}
```

---

## 5. Parent / Wali (Role: `parent`)

Endpoint khusus bagi orang tua / wali untuk melihat absensi anak (yang terhubung lewat `parent_id` di tabel `profiles`).

### 5.1 Riwayat Absensi Anak

* **Endpoint:** `/parent/children/attendances`
* **Method:** `GET`
* **Auth Required:** Yes (Bearer Token + Role `parent`)

**Response (200 OK):**
```json
{
    "children": [
        {
            "id": 2,
        }
    ]
}
```

---

## 6. Dashboards
Endpoint statistik untuk layar utama aplikasi. Dipanggil sesaat setelah berhasil login.

### 6.1 Dashboard User (Role Bebas)
* **Endpoint:** `/dashboard/user`
* **Method:** `GET`
* **Auth Required:** Yes

### 6.2 Dashboard Admin
* **Endpoint:** `/dashboard/admin`
* **Method:** `GET`
* **Auth Required:** Yes (Role `admin`)

### 6.3 Dashboard Parent
* **Endpoint:** `/dashboard/parent`
* **Method:** `GET`
* **Auth Required:** Yes (Role `parent`)

---

## 7. Permits (Izin / Sakit / Cuti)

### 7.1 Mengajukan Izin (User)
* **Endpoint:** `/permits`
* **Method:** `POST`
* **Auth Required:** Yes
* **Format:** `multipart/form-data` (Jika ada lampiran)
* **Payload:** `start_date`, `end_date`, `type` (izin/sakit/cuti), `reason`, `attachment` (file opsional).

### 7.2 Persetujuan Izin (Admin)
* **Endpoint:** `/admin/permits/{id}`
* **Method:** `PUT`
* **Auth Required:** Yes (Role `admin`)
* **Payload:** `{"status": "approved"}`