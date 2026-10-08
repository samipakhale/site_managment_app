import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<bool> registerUser(String identifier, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersList = prefs.getStringList('registered_users') ?? [];

    for (String userStr in usersList) {
      Map<String, dynamic> userMap = jsonDecode(userStr);
      if (userMap['identifier'] == identifier) {
        return false;
      }
    }

    Map<String, dynamic> newUser = {
      'identifier': identifier,
      'password': password,
    };
    usersList.add(jsonEncode(newUser));
    await prefs.setStringList('registered_users', usersList);
    return true;
  }

  Future<bool> checkLogin(String identifier, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersList = prefs.getStringList('registered_users') ?? [];

    for (String userStr in usersList) {
      Map<String, dynamic> userMap = jsonDecode(userStr);
      if (userMap['identifier'] == identifier && userMap['password'] == password) {
        return true;
      }
    }
    return false;
  }

  Future<void> insertSite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sitesList = prefs.getStringList('user_sites') ?? [];
    sitesList.add(name);
    await prefs.setStringList('user_sites', sitesList);
  }

  Future<List<Map<String, dynamic>>> getSites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sitesList = prefs.getStringList('user_sites') ?? [];
    return sitesList.map((site) => {'name': site}).toList();
  }

  // खर्च ॲड करणे
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'expense_${siteName}_$categoryName';
    List<String> expensesList = prefs.getStringList(key) ?? [];
    
    expenseData['id'] ??= DateTime.now().millisecondsSinceEpoch;
    expensesList.add(jsonEncode(expenseData));
    await prefs.setStringList(key, expensesList);
  }

  // खर्च फेच करणे
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'expense_${siteName}_$categoryName';
    List<String> expensesList = prefs.getStringList(key) ?? [];

    return expensesList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  // खर्च आयडीनुसार डिलीट करणे
  Future<void> deleteExpenseById(String siteName, String categoryName, int id) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'expense_${siteName}_$categoryName';
    List<String> expensesList = prefs.getStringList(key) ?? [];

    List<Map<String, dynamic>> decodedList = expensesList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    decodedList.removeWhere((expense) => expense['id'] == id);

    List<String> updatedList = decodedList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(key, updatedList);
  }

  // खर्च एडिट करून अपडेट करणे
  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'expense_${siteName}_$categoryName';
    List<String> expensesList = prefs.getStringList(key) ?? [];

    List<Map<String, dynamic>> decodedList = expensesList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    int index = decodedList.indexWhere((exp) => exp['id'] == updatedExpense['id']);
    if (index != -1) {
      decodedList[index] = updatedExpense;
    }

    List<String> updatedList = decodedList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(key, updatedList);
  }
}