import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _keyUsername = 'username';
  static const String _keyBudget = 'monthly_budget';
  static const String _keyPassword = 'password';

  static Future<void> saveUsername(String username) async {
    print('Saving username: $username');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    print('Username saved successfully');
  }

  static Future<String?> getUsername() async {
    print('Getting username...');
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    print('Retrieved username: $username');
    return username;
  }

  static Future<void> saveBudget(double budget) async {
    print('Saving budget: $budget');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBudget, budget);
    print('Budget saved successfully');
  }

  static Future<double> getBudget() async {
    print('Getting budget...');
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getDouble(_keyBudget) ?? 0.0;
    print('Retrieved budget: $budget');
    return budget;
  }

  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  static Future<void> clearAll() async {
    print('Clearing all preferences...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('All preferences cleared');
  }

  static Future<void> logout() async {
    print('Logging out...');
    final prefs = await SharedPreferences.getInstance();
    // Hapus username dan password, tapi biarkan budget
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    print('Logout completed - username and password removed');
  }
} 