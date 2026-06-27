import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/api_client.dart';

class ApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.dio.get('/settings');
      return response.data;
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await _apiClient.dio.get('/user');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/user/profile', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPublicFormFields() async {
    try {
      final response = await _apiClient.dio.get('/form-fields');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerFace(String faceBiometric) async {
    try {
      final response = await _apiClient.dio.post('/user/register-face', data: {
        'face_biometric': faceBiometric
      });
      return response.data;
    } catch (e) {
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/attendance/history');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/admin');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/user');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getParentDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/parent');
      return response.data;
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  // --- Admin: Users Management ---

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/users', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/users', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/users/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/users/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Schedules Management ---

  Future<Map<String, dynamic>> getSchedules({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/schedules', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/schedules', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/schedules/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSchedule(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/schedules/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Groups Management ---

  Future<Map<String, dynamic>> getGroups({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/groups', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGroup(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/groups/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteGroup(int id) async {
    try {
      final response = await _apiClient.dio.delete('/admin/groups/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> attachUserToGroup(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups/$groupId/attach-user', data: {
        'user_id': userId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detachUserFromGroup(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.post('/admin/groups/$groupId/detach-user', data: {
        'user_id': userId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Form Fields Management ---

  Future<List<dynamic>> getFormFields() async {
    try {
      final response = await _apiClient.dio.get('/admin/form-fields');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createFormField(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/form-fields', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateFormField(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/form-fields/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFormField(int id) async {
    try {
      await _apiClient.dio.delete('/admin/form-fields/$id');
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Attendances Management ---

  Future<Map<String, dynamic>> getAttendances({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/attendances', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/admin/attendances', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAttendance(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/admin/attendances/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await _apiClient.dio.delete('/admin/attendances/$id');
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Locations ---
  Future<Map<String, dynamic>> getLocations({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/locations', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createLocation(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/locations', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateLocation(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/locations/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteLocation(int id) async {
    try { await _apiClient.dio.delete('/admin/locations/'); } catch (e) { rethrow; }
  }

  // --- Admin: Roles ---
  Future<Map<String, dynamic>> getRoles({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/roles', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/roles', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateRole(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/roles/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteRole(int id) async {
    try { await _apiClient.dio.delete('/admin/roles/'); } catch (e) { rethrow; }
  }

  // --- Admin: Permits ---
  Future<Map<String, dynamic>> getPermits({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/permits', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createPermit(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/permits', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updatePermit(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/permits/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deletePermit(int id) async {
    try { await _apiClient.dio.delete('/admin/permits/'); } catch (e) { rethrow; }
  }

  // --- Admin: Holidays ---
  Future<Map<String, dynamic>> getHolidays({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/holidays', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/holidays', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/holidays/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteHoliday(int id) async {
    try { await _apiClient.dio.delete('/admin/holidays/'); } catch (e) { rethrow; }
  }

  // --- Admin: Shifts ---
  Future<Map<String, dynamic>> getShifts({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/shifts', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createShift(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/shifts', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateShift(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/shifts/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteShift(int id) async {
    try { await _apiClient.dio.delete('/admin/shifts/'); } catch (e) { rethrow; }
  }

  // --- Admin: Rosters ---
  Future<Map<String, dynamic>> getRosters({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/rosters', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createRoster(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/rosters', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateRoster(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/rosters/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteRoster(int id) async {
    try { await _apiClient.dio.delete('/admin/rosters/'); } catch (e) { rethrow; }
  }

  // --- Admin: Announcements ---
  Future<Map<String, dynamic>> getAnnouncements({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get('/admin/announcements', queryParameters: {'page': page, if (search != null && search.isNotEmpty) 'search': search});
      return response.data;
    } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.post('/admin/announcements', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> data) async {
    try { final response = await _apiClient.dio.put('/admin/announcements/', data: data); return response.data; } catch (e) { rethrow; }
  }
  Future<void> deleteAnnouncement(int id) async {
    try { await _apiClient.dio.delete('/admin/announcements/'); } catch (e) { rethrow; }
  }



  // --- Notifications & FCM ---

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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final response = await _apiClient.dio.put('/notifications//read');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await _apiClient.dio.post('/notifications/read-all');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

}