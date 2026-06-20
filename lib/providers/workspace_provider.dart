import 'package:flutter/material.dart';

class WorkspaceProvider with ChangeNotifier {
  String _activeMode = 'absen'; // 'absen', 'admin', 'parent'

  String get activeMode => _activeMode;

  void setMode(String mode) {
    if (_activeMode != mode) {
      _activeMode = mode;
      notifyListeners();
    }
  }

  /// Evaluates available modes based on user data
  List<String> getAvailableModes(Map<String, dynamic>? user) {
    if (user == null) return [];
    
    List<String> modes = [];
    
    // Check if user is an admin
    if (user['role']?['name'] == 'admin') {
      modes.add('admin');
    }
    
    // Check if user is a parent
    if (user['role']?['name'] == 'parent') {
      modes.add('parent');
    }
    
    // Check if user can attend
    if (user['can_attend'] == true) {
      modes.add('absen');
    }

    return modes;
  }
}
