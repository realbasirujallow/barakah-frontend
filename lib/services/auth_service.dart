import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Secure storage for sensitive data (JWT, userId)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<void> init() async {
    // Read sensitive data from secure storage
    _token = await _secureStorage.read(key: _tokenKey);
    _userId = await _secureStorage.read(key: _userIdKey);

    // Read non-sensitive display data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);

    // Migrate from old plaintext storage if needed
    if (_token == null) {
      final oldToken = prefs.getString(_tokenKey);
      if (oldToken != null) {
        _token = oldToken;
        _userId = prefs.getString(_userIdKey);
        // Move to secure storage
        await _secureStorage.write(key: _tokenKey, value: _token);
        if (_userId != null) {
          await _secureStorage.write(key: _userIdKey, value: _userId);
        }
        // Remove from plaintext storage
        await prefs.remove(_tokenKey);
        await prefs.remove(_userIdKey);
      }
    }

    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await _secureStorage.read(key: _tokenKey);
    return _token;
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    _token = token;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;

    // Store sensitive data in secure storage
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userIdKey, value: userId);

    // Store non-sensitive display data in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;

    // Clear secure storage
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    notifyListeners();
  }
}
