import 'package:dio/dio.dart';
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
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photoPath),
        ));
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
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photoPath),
        ));
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
      final response = await _apiClient.dio.post('/admin/settings', data: {
        'settings': settings
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin: Users Management ---

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _apiClient.dio.get('/admin/users');
      return response.data; // Backend returns JSON array directly or {data: ...} depending on framework, but the controller says response()->json(User::with...get()) which is a JSON array
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

  Future<List<dynamic>> getSchedules() async {
    try {
      final response = await _apiClient.dio.get('/admin/schedules');
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

  Future<List<dynamic>> getGroups() async {
    try {
      final response = await _apiClient.dio.get('/admin/groups');
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

  Future<List<dynamic>> getAttendances() async {
    try {
      final response = await _apiClient.dio.get('/admin/attendances');
      return response.data['attendances'] ?? [];
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
}
