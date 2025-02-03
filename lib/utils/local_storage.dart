
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserDetails(String name) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('userName', name);
}

Future<String?> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userName');
}

Future<void> clearUserDetails() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove('userName');
}
