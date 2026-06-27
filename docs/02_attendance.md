# Absensi (Attendance)

## 1. Check In
Mencatat absensi masuk untuk hari ini.
* **Endpoint:** `/attendance/check-in`
* **Method:** `POST`
* **Auth Required:** Yes
* **Catatan:** Backend akan otomatis mengkalkulasi keterlambatan (`is_late` dan `late_minutes`) berdasarkan Jadwal Grup atau Jadwal Default.

## 2. Check Out
Mencatat absensi pulang.
* **Endpoint:** `/attendance/check-out`
* **Method:** `POST`
* **Auth Required:** Yes

## 3. History (Riwayat Absensi)
* **Endpoint:** `/attendance/history`
* **Method:** `GET`
* **Auth Required:** Yes
