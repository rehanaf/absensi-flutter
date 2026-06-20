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
}
