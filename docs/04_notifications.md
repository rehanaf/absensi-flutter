# Notifikasi (Push Notifications)

Endpoint ini digunakan untuk mengelola *Notification Center* (Lonceng 🔔) di aplikasi Flutter maupun Web, serta pendaftaran token Firebase.

## 1. Mendaftarkan Token FCM
Wajib dipanggil oleh Flutter setiap kali berhasil *Login* atau *Startup* agar *Backend* tahu HP mana yang harus dikirimi *Push Notification*.
* **Endpoint:** `/user/fcm-token`
* **Method:** `POST`
* **Auth Required:** Yes
* **Payload:** 
  ```json
  {
      "fcm_token": "eY8x_AbC...",
      "device_name": "iPhone 13 Pro"
  }
  ```

## 2. Mengambil Riwayat Notifikasi
* **Endpoint:** `/notifications`
* **Method:** `GET`
* **Auth Required:** Yes
* **Response (200 OK):**
  ```json
  {
      "notifications": [
          {
              "id": 1,
              "title": "Izin Disetujui",
              "message": "Pengajuan cuti Anda telah disetujui.",
              "is_read": false,
              "created_at": "2026-06-25T10:00:00.000000Z"
          }
      ]
  }
  ```

## 3. Menandai 1 Notifikasi Dibaca
* **Endpoint:** `/notifications/{id}/read`
* **Method:** `PUT`
* **Auth Required:** Yes

## 4. Menandai Semua Dibaca
* **Endpoint:** `/notifications/read-all`
* **Method:** `POST`
* **Auth Required:** Yes
