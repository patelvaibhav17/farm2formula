import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _defaultIp = '192.168.31.141';
  static const String _storageKey = 'server_ip';

  // Production-level timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  static SharedPreferences? _prefs;

  // Initialize prefs and load the current IP
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get serverIp {
    return _prefs?.getString(_storageKey) ?? _defaultIp;
  }

  static Future<void> updateServerIp(String newIp) async {
    if (_prefs != null) {
      await _prefs!.setString(_storageKey, newIp);
    }
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    } else {
      return 'http://$serverIp:3000/api/v1';
    }
  }

  static String get baseDomain {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://$serverIp:3000';
    }
  }

  /// Formats common errors (like timeouts) into user-friendly messages for production.
  static String formatError(dynamic error) {
    final String errStr = error.toString();
    if (errStr.contains('TimeoutException') || errStr.contains('Future not completed')) {
      return 'Connection timed out. The blockchain is taking longer than usual to respond. Please try again.';
    }
    if (errStr.contains('SocketException') || errStr.contains('Connection refused')) {
      return 'Cannot connect to server. Please check your internet connection and server IP settings.';
    }
    if (errStr.contains('404')) {
      return 'Requested resource not found on server.';
    }
    // Strip "Exception: " prefix if present for cleaner UI
    return errStr.replaceFirst('Exception: ', '').replaceFirst('error: ', '');
  }
}