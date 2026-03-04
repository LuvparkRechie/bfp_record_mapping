import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoreCredentials {
  static Future<void> saveUserData(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_data', json.encode(sessionData));
  }

  static Future<dynamic> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString('user_data');

    if (result == null) return null;
    return json.decode(result);
  }
}
