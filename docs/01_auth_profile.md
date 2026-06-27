# Autentikasi & Profil

## 1. Login
Melakukan login untuk mendapatkan *Access Token*.
* **Endpoint:** `/login`
* **Method:** `POST`

## 2. Get User (Me)
Mendapatkan data *User* yang sedang login beserta role, profil, dan grup (kelas/divisi) nya.
* **Endpoint:** `/user`
* **Method:** `GET`
* **Auth Required:** Yes (Bearer Token)

## 3. Update Profil User
Memperbarui data diri User (nama, email, phone, dsb). Hanya kolom yang diizinkan oleh Admin di `Settings` (seperti `user_can_edit_name`) yang akan benar-benar terupdate. Custom fields juga hanya diupdate jika `is_editable` = true.
* **Endpoint:** `/user/profile`
* **Method:** `PUT`
* **Auth Required:** Yes
**Request Body:**
```json
{
    "name": "Nama Baru",
    "phone_number": "08123456",
    "custom_fields": {
        "alamat": "Jalan Baru No. 2"
    }
}
```

## 4. Register Face (User Side)
Mendaftarkan wajah *user* untuk pertama kali dari HP mereka (berupa base64 image string).
* **Endpoint:** `/user/register-face`
* **Method:** `POST`
* **Auth Required:** Yes
**Request Body:**
```json
{
    "face_biometric": "base64encodedstring..."
}
```

## 5. Logout
* **Endpoint:** `/logout`
* **Method:** `POST`
* **Auth Required:** Yes
