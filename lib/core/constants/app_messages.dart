import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AppMessages {
  static Map<String, String> _messages = {};
  static String _appMode = 'perusahaan';

  static Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/messages.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _messages = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load messages.json: $e');
      }
    }
  }

  static void setAppMode(String mode) {
    _appMode = mode.toLowerCase();
    if (kDebugMode) {
      print('AppMessages mode set to: $_appMode');
    }
  }

  /// Resolves a message key or raw text to its translation.
  /// Dynamically maps Parent/Child terms to Company terms if _appMode is 'perusahaan'.
  /// Also enforces correct "Presensi" and "Tidak Hadir" terminology.
  static String get(String key) {
    String resolved = key;

    // 1. Dynamic Mode Translation (Sekolah vs Perusahaan)
    if (_appMode == 'perusahaan') {
      final companyMappings = {
        'Wali/Parent': 'Atasan/Supervisor',
        'Anak Saya': 'Staff Bawahan',
        'Riwayat Anak': 'Riwayat Staff',
        'Hubungkan Anak': 'Hubungkan Karyawan',
        'Dasbor Orang Tua': 'Dasbor Atasan',
        'Wali': 'Atasan',
        'Anak': 'Bawahan',
        'Siswa/Karyawan': 'Karyawan',
        'Orang Tua': 'Atasan',
        'NIS/NIP': 'NIP / ID Karyawan',
        'Pendaftaran Wali': 'Pendaftaran Atasan',
        'Pendaftaran Siswa': 'Pendaftaran Karyawan',
        'Siswa': 'Karyawan',
        'Detail Anak': 'Detail Staff',
        'Nama Anak': 'Nama Staff',
        'parent': 'atasan',
        'siswa': 'karyawan',
        'wali': 'atasan',
        'wali murid': 'atasan',
        'Parent': 'Atasan',
        'Siswa': 'Karyawan',
        'Wali': 'Atasan',
        'Wali Murid': 'Atasan',
        'role_parent': 'atasan',
        'role_siswa': 'karyawan',
        'Daftar Anak Terhubung': 'Daftar Staff Terhubung',
        'Daftar Anak': 'Daftar Staff',
        'Belum ada data anak tertaut.': 'Belum ada data staff tertaut.',
        'Hubungkan Anak Baru': 'Hubungkan Staff Baru',
        'Permintaan Hubungan Anak': 'Permintaan Hubungan Staff',
        'Username Anak (NIS/NIP)': 'Username Staff (NIP)',
        'Belum ada anak yang terhubung': 'Belum ada staff yang terhubung',
        'Informasi Anak': 'Informasi Staff',
      };
      
      if (companyMappings.containsKey(key)) {
        resolved = companyMappings[key]!;
      } else {
        resolved = _messages[key] ?? key;
        companyMappings.forEach((schoolTerm, companyTerm) {
          resolved = resolved.replaceAll(schoolTerm, companyTerm);
        });
      }
    } else {
      resolved = _messages[key] ?? key;
    }

    // 2. Global Absen/Absensi -> Presensi & Alpa -> Tidak Hadir Translation
    final globalReplacements = {
      'Absen Masuk': 'Presensi Masuk',
      'Absen Pulang': 'Presensi Pulang',
      'Riwayat Absensi': 'Riwayat Kehadiran',
      'Riwayat Absen': 'Riwayat Kehadiran',
      'Aplikasi Absensi': 'Aplikasi Presensi',
      'Detail Absensi': 'Detail Kehadiran',
      'Laporan Absensi': 'Laporan Kehadiran',
      'Absensi': 'Presensi',
      'absensi': 'presensi',
      'Belum Absen': 'Belum Presensi',
      'belum absen': 'belum presensi',
      'Alpa': 'Tidak Hadir',
      'alpa': 'tidak hadir',
    };

    if (globalReplacements.containsKey(resolved)) {
      resolved = globalReplacements[resolved]!;
    } else {
      globalReplacements.forEach((oldTerm, newTerm) {
        resolved = resolved.replaceAll(oldTerm, newTerm);
      });
    }

    // 3. Fallback prefix match from JSON for toast/api errors
    for (var entry in _messages.entries) {
      if (key.startsWith(entry.key)) {
        resolved = resolved.replaceFirst(entry.key, entry.value);
        break;
      }
    }

    return resolved;
  }

  // Auth Messages
  static String get loginSuccess => get('Login Berhasil!');
  static String get loginFailed => get('Email atau Password salah');
  static String get registerSuccess => get('Pendaftaran Berhasil! Silakan Login');
  static String get registerFailed => get('Pendaftaran Gagal');
  static String get logoutSuccess => get('Berhasil keluar');

  // Profile / Settings Messages
  static String get profileUpdateSuccess => get('Foto profil berhasil diperbarui!');
  static String get profileUpdateFailed => get('Gagal memperbarui foto profil');
  static String get passwordUpdateSuccess => get('Password berhasil diubah!');
  static String get passwordUpdateFailed => get('Gagal mengubah password');
  static String get settingsSaved => get('Pengaturan berhasil disimpan!');
  static String get settingsSaveFailed => get('Gagal menyimpan pengaturan');

  // Attendance Messages
  static String get checkInSuccess => get('Absen masuk berhasil dilakukan!');
  static String get checkInFailed => get('Gagal absen masuk');
  static String get checkOutSuccess => get('Absen pulang berhasil dilakukan!');
  static String get checkOutFailed => get('Gagal absen pulang');
  static String get locationRequired => get('Izin lokasi dibutuhkan untuk melakukan absensi');
  static String get locationMocked => get('Deteksi GPS palsu (Mock Location) terdeteksi!');
  static String get faceVerificationFailed => get('Verifikasi wajah gagal dilakukan');

  // Submission / Permit / Overtime Messages
  static String get permitSubmitSuccess => get('Pengajuan izin berhasil dikirim!');
  static String get permitSubmitFailed => get('Gagal mengirim pengajuan izin');
  static String get activitySubmitSuccess => get('Pengajuan aktivitas/lembur berhasil dikirim!');
  static String get activitySubmitFailed => get('Gagal mengirim pengajuan aktivitas/lembur');
  
  // General Admin / Management Messages
  static String get deleteSuccess => get('Data berhasil dihapus');
  static String get deleteFailed => get('Gagal menghapus data');
  static String get saveSuccess => get('Data berhasil disimpan');
  static String get saveFailed => get('Gagal menyimpan data');
}
