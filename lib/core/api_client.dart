import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  static void Function()? onUnauthorized;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add bearer token if exists
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('user');
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
