import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class AppSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _appName = 'Absensi App';
  String _identityLabel = 'ID';
  String _themeColorName = 'zinc';
  bool _requireLocation = false;
  String _attendanceMode = 'none';
  bool _allowRegistration = false;
  double _officeLat = -6.200000;
  double _officeLng = 106.816666;
  String _locationName = 'Lokasi Kantor';
  double _officeRadius = 50.0;
  List<dynamic> _dynamicFields = [];
  List<dynamic> _roles = [];
  List<dynamic> _rawSettings = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get appName => _appName;
  String get identityLabel => _identityLabel;
  String get themeColorName => _themeColorName;
  bool get requireLocation => _requireLocation;
  String get attendanceMode => _attendanceMode;
  bool get allowRegistration => _allowRegistration;
  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  String get locationName => _locationName;
  double get officeRadius => _officeRadius;
  List<dynamic> get dynamicFields => _dynamicFields;
  List<dynamic> get roles => _roles;
  List<dynamic> get rawSettings => _rawSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? getSetting(String key) {
    for (var item in _rawSettings) {
      if (item is Map && item['key'] == key) {
        return item['value']?.toString();
      }
    }
    return null;
  }

  String? getSettingImageUrl(String key) {
    for (var item in _rawSettings) {
      if (item is Map && item['key'] == key) {
        return item['image_url']?.toString();
      }
    }
    return null;
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final data = await _apiService.getSettings();
      final settings = data['settings'];
      if (settings is List) {
        _rawSettings = settings;
        final Map<String, dynamic> settingsMap = {};
        for (var item in settings) {
          if (item is Map) {
            settingsMap[item['key']] = item['value'];
          }
        }
        
        _appName = settingsMap['app_name'] ?? _appName;
        _identityLabel = settingsMap['username_label'] ?? _identityLabel;
        
        if (settingsMap['theme_color'] != null) {
          _themeColorName = settingsMap['theme_color'].toString().toLowerCase();
        }
        
        _requireLocation = settingsMap['require_location']?.toString() == '1' || settingsMap['require_location']?.toString().toLowerCase() == 'true';
        _attendanceMode = settingsMap['attendance_mode']?.toString() ?? 'none';
        _allowRegistration = settingsMap['allow_registration']?.toString() == '1' || settingsMap['allow_registration']?.toString().toLowerCase() == 'true';

        if (settingsMap['center_latitude'] != null) {
          _officeLat = double.tryParse(settingsMap['center_latitude'].toString()) ?? _officeLat;
        }
        if (settingsMap['center_longitude'] != null) {
          _officeLng = double.tryParse(settingsMap['center_longitude'].toString()) ?? _officeLng;
        }
        if (settingsMap['location_name'] != null) {
          _locationName = settingsMap['location_name'].toString();
        }
        if (settingsMap['office_radius'] != null) {
          _officeRadius = double.tryParse(settingsMap['office_radius'].toString()) ?? _officeRadius;
        }
      } else if (settings is Map) {
        // Fallback backward compatibility
        _appName = settings['app_name'] ?? _appName;
        _identityLabel = settings['username_label'] ?? _identityLabel;
        if (settings['theme_color'] != null) {
          _themeColorName = settings['theme_color'].toString().toLowerCase();
        }
        _requireLocation = settings['require_location']?.toString() == '1' || settings['require_location']?.toString().toLowerCase() == 'true';
        _attendanceMode = settings['attendance_mode']?.toString() ?? 'none';
        _allowRegistration = settings['allow_registration']?.toString() == '1' || settings['allow_registration']?.toString().toLowerCase() == 'true';

        if (settings['center_latitude'] != null) {
          _officeLat = double.tryParse(settings['center_latitude'].toString()) ?? _officeLat;
        }
        if (settings['center_longitude'] != null) {
          _officeLng = double.tryParse(settings['center_longitude'].toString()) ?? _officeLng;
        }
        if (settings['location_name'] != null) {
          _locationName = settings['location_name'].toString();
        }
        if (settings['office_radius'] != null) {
          _officeRadius = double.tryParse(settings['office_radius'].toString()) ?? _officeRadius;
        }
      }

      if (data['dynamic_fields'] != null) {
        _dynamicFields = data['dynamic_fields'];
      }

      if (data['roles'] != null) {
        _roles = data['roles'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
