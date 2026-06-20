import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class AppSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _appName = 'Absensi App';
  String _identityLabel = 'ID';
  String _themeColorName = 'zinc';
  bool _requireLocation = false;
  bool _requireFace = false;
  bool _requirePhoto = false;
  List<dynamic> _dynamicFields = [];
  List<dynamic> _roles = [];
  List<dynamic> _rawSettings = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get appName => _appName;
  String get identityLabel => _identityLabel;
  String get themeColorName => _themeColorName;
  bool get requireLocation => _requireLocation;
  bool get requireFace => _requireFace;
  bool get requirePhoto => _requirePhoto;
  List<dynamic> get dynamicFields => _dynamicFields;
  List<dynamic> get roles => _roles;
  List<dynamic> get rawSettings => _rawSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
        
        _requireLocation = settingsMap['require_location'] == '1' || settingsMap['require_location'] == true;
        _requireFace = settingsMap['require_face'] == '1' || settingsMap['require_face'] == true;
        _requirePhoto = settingsMap['require_photo'] == '1' || settingsMap['require_photo'] == true;
      } else if (settings is Map) {
        // Fallback backward compatibility
        _appName = settings['app_name'] ?? _appName;
        _identityLabel = settings['username_label'] ?? _identityLabel;
        if (settings['theme_color'] != null) {
          _themeColorName = settings['theme_color'].toString().toLowerCase();
        }
        _requireLocation = settings['require_location'] == '1' || settings['require_location'] == true;
        _requireFace = settings['require_face'] == '1' || settings['require_face'] == true;
        _requirePhoto = settings['require_photo'] == '1' || settings['require_photo'] == true;
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
