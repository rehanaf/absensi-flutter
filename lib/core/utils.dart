import 'package:flutter/material.dart';

class Utils {
  static Color hexToColor(String hexString) {
    var hexColor = hexString.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }
    return Colors.blue; // Default fallback
  }
}
