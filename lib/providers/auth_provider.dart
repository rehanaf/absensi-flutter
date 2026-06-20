import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    
    if (_token != null) {
      try {
        final userData = await _apiService.getUser();
        _user = userData;
      } catch (e) {
        // Token might be invalid
        await logout();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email, password);
      _token = data['access_token'];
      _user = data['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      
      if (e is DioException) {
        if (e.response != null && e.response?.data != null) {
          // If the backend returns a JSON with a 'message' field
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            _errorMessage = responseData['message'];
          } else {
            _errorMessage = 'Login failed: ${e.response?.statusCode}';
          }
        } else {
          _errorMessage = 'Network error: ${e.message}';
        }
      } else {
        _errorMessage = 'Login failed. Please check your credentials.';
      }
      
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
