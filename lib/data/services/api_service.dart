import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/api_client.dart';


class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.dio.get('/settings');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/register', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/login', data: {
        'username': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await _apiClient.dio.get('/user');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      dynamic requestData;
      bool hasFile = data.values.any((val) => val is MultipartFile);
      if (hasFile) {
        data['_method'] = 'PUT';
        requestData = FormData.fromMap(data);
        final response = await _apiClient.dio.post('/user/profile', data: requestData);
        return response.data;
      } else {
        final response = await _apiClient.dio.put('/user/profile', data: data);
        return response.data;
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Attendance Activities (Lembur / Tugas Luar) ---
  Future<Map<String, dynamic>> getMyAttendanceActivities() async {
    try {
      final response = await _apiClient.dio.get('/attendance-activities');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> submitMyAttendanceActivity(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/attendance-activities', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Permits (Izin / Sakit / Cuti) ---
  Future<dynamic> getMyPermits() async {
    try {
      final response = await _apiClient.dio.get('/permits');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> submitMyPermit(Map<String, dynamic> data, {String? attachmentPath}) async {
    try {
      FormData formData = FormData.fromMap(data);
      if (attachmentPath != null) {
        formData.files.add(
          MapEntry('attachment', await MultipartFile.fromFile(attachmentPath)),
        );
      }
      
      final response = await _apiClient.dio.post('/permits', data: formData);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<List<dynamic>> getPublicFormFields() async {
    try {
      final response = await _apiClient.dio.get('/form-fields');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> registerFace(String faceBiometric) async {
    try {
      final response = await _apiClient.dio.post('/user/register-face', data: {
        'face_biometric': faceBiometric
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> checkIn(double lat, double lng, {String? photoPath}) async {
    try {
      final formData = FormData.fromMap({
        'location_data[lat]': lat,
        'location_data[lng]': lng,
      });

      if (photoPath != null) {
        if (kIsWeb) {
          final bytes = base64Decode(photoPath);
          formData.files.add(MapEntry(
            'photo',
            MultipartFile.fromBytes(bytes, filename: 'photo.jpg'),
          ));
        } else {
          formData.files.add(MapEntry(
            'photo',
            await MultipartFile.fromFile(photoPath),
          ));
        }
      }

      final response = await _apiClient.dio.post(
        '/attendance/check-in',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> checkOut(double lat, double lng, {String? photoPath}) async {
    try {
      final formData = FormData.fromMap({
        'location_data[lat]': lat,
        'location_data[lng]': lng,
      });

      if (photoPath != null) {
        if (kIsWeb) {
          final bytes = base64Decode(photoPath);
          formData.files.add(MapEntry(
            'photo',
            MultipartFile.fromBytes(bytes, filename: 'photo.jpg'),
          ));
        } else {
          formData.files.add(MapEntry(
            'photo',
            await MultipartFile.fromFile(photoPath),
          ));
        }
      }

      final response = await _apiClient.dio.post(
        '/attendance/check-out',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/attendance/history');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/admin');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getUserDashboard({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      
      final response = await _apiClient.dio.get('/dashboard/user', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getParentDashboard({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      
      final response = await _apiClient.dio.get('/dashboard/parent', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getParentHistory() async {
    try {
      final response = await _apiClient.dio.get('/parent/children/attendances');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getParentChildrenRequests() async {
    try {
      final response = await _apiClient.dio.get('/parent/children/requests');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> connectParentChild(String username) async {
    try {
      final response = await _apiClient.dio.post('/parent/children/connect', data: {
        'username': username,
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateAdminSettings(Map<String, dynamic> settings) async {
    try {
      FormData formData = FormData();
      bool hasFile = false;
      
      for (var entry in settings.entries) {
        if (entry.value is MultipartFile) {
          hasFile = true;
          formData.files.add(MapEntry('settings[${entry.key}]', entry.value));
        } else if (entry.value != null) {
          formData.fields.add(MapEntry('settings[${entry.key}]', entry.value.toString()));
        }
      }

      final response = await _apiClient.dio.post(
        '/admin/settings',
        data: hasFile ? formData : { 'settings': settings },
      );
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Users Management ---

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/users', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/users', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/users/$id', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/users/$id');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> getAdminParentChildRequests({int page = 1, String? status}) async {
    try {
      final response = await _apiClient.dio.get('/admin/parent-child-requests', queryParameters: {
        'page': page,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> approveParentChildRequest(int id) async {
    try {
      final response = await _apiClient.dio.put('/admin/parent-child-requests/$id/approve');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> rejectParentChildRequest(int id) async {
    try {
      final response = await _apiClient.dio.put('/admin/parent-child-requests/$id/reject');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Schedules Management ---

  Future<Map<String, dynamic>> getSchedules({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/schedules', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/schedules', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/schedules/$id', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> deleteSchedule(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/schedules/$id');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Groups Management ---

  Future<Map<String, dynamic>> getGroups({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/groups', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateGroup(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/groups/$id', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> deleteGroup(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/groups/$id');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> attachUserToGroup(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups/$groupId/attach-user', data: {
        'user_id': userId,
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> detachUserFromGroup(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups/$groupId/detach-user', data: {
        'user_id': userId,
      });
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Form Fields Management ---

  Future<List<dynamic>> getFormFields() async {
    try {
      final response = await _apiClient.dio.get('/admin/form-fields');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> createFormField(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/form-fields', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateFormField(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/form-fields/$id', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<void> deleteFormField(int id) async {
    try {
      await _apiClient.dio.delete('/admin/form-fields/$id');
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Attendances Management ---

  Future<Map<String, dynamic>> getAttendances({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/attendances', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/attendances', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> updateAttendance(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/attendances/$id', data: data);
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await _apiClient.dio.delete('/admin/attendances/$id');
    } catch (e) {
      throw _handleException(e);
    }
  }

  // --- Admin: Locations ---
  Future<Map<String, dynamic>> getLocations({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/locations', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createLocation(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/locations', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateLocation(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/locations/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteLocation(int id) async {
    try { await _apiClient.dio.delete('/admin/locations/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Roles ---
  Future<Map<String, dynamic>> getRoles({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/roles', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/roles', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateRole(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/roles/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteRole(int id) async {
    try { await _apiClient.dio.delete('/admin/roles/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Permits ---
  Future<Map<String, dynamic>> getPermits({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/permits', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createPermit(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/permits', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updatePermit(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/permits/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deletePermit(int id) async {
    try { await _apiClient.dio.delete('/admin/permits/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Holidays ---
  Future<Map<String, dynamic>> getHolidays({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/holidays', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/holidays', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/holidays/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteHoliday(int id) async {
    try { await _apiClient.dio.delete('/admin/holidays/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Shifts ---
  Future<Map<String, dynamic>> getShifts({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/shifts', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createShift(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/shifts', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateShift(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/shifts/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteShift(int id) async {
    try { await _apiClient.dio.delete('/admin/shifts/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Rosters ---
  Future<Map<String, dynamic>> getRosters({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/rosters', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createRoster(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/rosters', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateRoster(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/rosters/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteRoster(int id) async {
    try { await _apiClient.dio.delete('/admin/rosters/$id'); } catch (e) { throw _handleException(e); }
  }

  // --- Admin: Announcements ---
  Future<Map<String, dynamic>> getAnnouncements({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/announcements', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/announcements', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/announcements/$id', data: data); return response.data; } catch (e) { throw _handleException(e); }
  }
  Future<void> deleteAnnouncement(int id) async {
    try { await _apiClient.dio.delete('/admin/announcements/$id'); } catch (e) { throw _handleException(e); }
  }



  // --- Notifications & FCM ---

  Future<Map<String, dynamic>> sendTestNotification() async {
    try {
      final response = await _apiClient.dio.post('/user/test-notification');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> registerFcmToken(String fcmToken, {String? deviceName}) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/fcm-token',
        data: {
          'fcm_token': fcmToken,
          if (deviceName != null) 'device_name': deviceName,
        }
      );
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<dynamic> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final response = await _apiClient.dio.put('/notifications/$id/read');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await _apiClient.dio.post('/notifications/read-all');
      return response.data;
    } catch (e) {
      throw _handleException(e);
    }
  }


  Exception _handleException(dynamic e) {
    if (e is DioException) {
      return AppException(_getFriendlyErrorMessage(e));
    }
    if (e is Exception) {
      return e;
    }
    return AppException(e.toString());
  }

  String _getFriendlyErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi waktu habis. Silakan periksa koneksi internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan server aktif dan internet Anda tersambung.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          
          // Handle Laravel validation errors
          if (status == 422 && data.containsKey('errors') && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final List<String> messages = [];
            for (var entry in errors.entries) {
              if (entry.value is List) {
                messages.addAll((entry.value as List).map((v) => v.toString()));
              } else {
                messages.add(entry.value.toString());
              }
            }
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          }
          
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
        }
        
        switch (status) {
          case 400:
            return 'Permintaan tidak valid.';
          case 401:
            return 'Sesi masuk telah berakhir. Silakan masuk kembali.';
          case 403:
            return 'Anda tidak memiliki akses untuk tindakan ini.';
          case 404:
            return 'Layanan atau data tidak ditemukan.';
          case 500:
            return 'Terjadi kesalahan internal pada server. Silakan hubungi admin.';
          default:
            return 'Terjadi kesalahan dengan kode status: $status';
        }
      default:
        return e.message ?? 'Terjadi kesalahan yang tidak diketahui.';
    }
  }

}