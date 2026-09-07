import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyApiUrl = 'api_url';
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  String get apiUrl => _prefs.getString(_keyApiUrl) ?? 'http://localhost:8000';
  set apiUrl(String url) => _prefs.setString(_keyApiUrl, url);

  String? get token => _prefs.getString(_keyToken);
  set token(String? t) => _prefs.setString(_keyToken, t ?? '');

  String? get userId => _prefs.getString(_keyUserId);
  set userId(String? id) => _prefs.setString(_keyUserId, id ?? '');

  String? get username => _prefs.getString(_keyUsername);
  set username(String? name) => _prefs.setString(_keyUsername, name ?? '');

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> clear() async {
    await _prefs.clear();
  }

  Map<String, dynamic> toJson() => {
        'api_url': apiUrl,
        'token': token,
        'user_id': userId,
        'username': username,
        'is_logged_in': isLoggedIn,
      };

  @override
  String toString() => jsonEncode(toJson());
}

// Convenience getter for app-wide usage
StorageService? _instance;

Future<StorageService> get storageService async {
  if (_instance != null) return _instance!;
  final prefs = await SharedPreferences.getInstance();
  _instance = StorageService(prefs);
  return _instance!;
}
