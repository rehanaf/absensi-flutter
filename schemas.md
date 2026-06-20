# DATABASE SCHEMA - ABSENSI APP (WHITE LABEL)

1. TABLE: roles
   - id (BIGINT)
   - name (VARCHAR)         -- 'admin', 'supervisor', 'user'
   - display_name (VARCHAR) -- 'Administrator', 'Atasan', 'Pengguna'

2. TABLE: permissions
   - id (BIGINT)
   - name (VARCHAR)         -- 'edit_absensi', 'approve_lembur'

3. TABLE: role_permission (Pivot)
   - role_id (BIGINT, FK)
   - permission_id (BIGINT, FK)

4. TABLE: settings
   - id (BIGINT)
   - key (VARCHAR)          -- 'app_name', 'identity_label'
   - value (TEXT)
   - created_at, updated_at

5. TABLE: form_fields
   - id (BIGINT)
   - field_label (VARCHAR)
   - field_name (VARCHAR)
   - field_type (VARCHAR)
   - is_required (BOOLEAN)
   - created_at, updated_at

6. TABLE: users
   - id (BIGINT)
   - role_id (BIGINT, FK)   -- Relasi ke tabel roles
   - name (VARCHAR)
   - email (VARCHAR, UNIQUE)
   - password (VARCHAR)
   - identity_code (VARCHAR)
   - phone_number (VARCHAR)
   - face_biometric (TEXT)  -- Referensi vektor biometrik wajah
   - can_attend (BOOLEAN)   -- Menentukan apakah role ini punya fitur absen (default: true)
   - created_at, updated_at

7. TABLE: profiles
   - id (BIGINT)
   - user_id (BIGINT, FK)
   - parent_id (BIGINT, FK)
   - meta_data (JSON)       -- Data dinamis (Kelas/Divisi/Fakultas)
   - created_at, updated_at

8. TABLE: groups
   - id (BIGINT)
   - name (VARCHAR)
   - type (VARCHAR)         -- 'divisi', 'kelas', 'fakultas'
   - created_at, updated_at

9. TABLE: group_user
   - id (BIGINT)
   - user_id (BIGINT, FK)
   - group_id (BIGINT, FK)

10. TABLE: schedules
    - id (BIGINT)
    - group_id (BIGINT, FK)
    - day (VARCHAR)
    - start_time (TIME)
    - end_time (TIME)
    - is_flexible (BOOLEAN)

11. TABLE: attendances
    - id (BIGINT)
    - user_id (BIGINT, FK)
    - date (DATE)
    - check_in (TIME)
    - check_out (TIME)
    - status (ENUM)          -- 'hadir', 'alpha', 'izin', 'sakit'
    - location_data (JSON)
    - photo_path (VARCHAR)   -- Lokasi penyimpanan bukti foto wajah

12. TABLE: attendance_activities
    - id (BIGINT)
    - attendance_id (BIGINT, FK)
    - activity_type (ENUM)   -- 'lembur', 'tugas_luar'
    - start_time (TIME)
    - end_time (TIME)
    - description (TEXT)
    - status_approval (ENUM) -- 'pending', 'approved', 'rejected'
    - meta_data (JSON)       -- bukti foto, dll