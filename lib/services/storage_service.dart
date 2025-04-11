import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'user_data';
  static const String _roleKey = 'user_role';
  static const String _hasSeenGetStartedKey = 'has_seen_get_started';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> markGetStartedAsSeen() async {
    await _prefs.setBool(_hasSeenGetStartedKey, true);
  }

  bool hasSeenGetStarted() {
    return _prefs.getBool(_hasSeenGetStartedKey) ?? false;
  }

  Future<String?> getAccessToken() async {
    try {
      final token = _prefs.getString(_accessTokenKey);
      print(
          'Retrieved token from storage: ${token != null ? "${token.substring(0, 10)}..." : "null"}');

      if (token == null) {
        print('No access token found in storage');
        return null;
      }

      // Check expiry
      final expiryStr = _prefs.getString(_tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          print('Token is expired, attempting refresh');
          final refreshedToken = await refreshAccessToken();
          if (refreshedToken != null) {
            print('Token refreshed successfully');
            return refreshedToken;
          }
          print('Token refresh failed');
          await clearTokens(); // Clear invalid tokens
          return null;
        }
      }

      // Double check the token is still there (race condition check)
      final verifyToken = _prefs.getString(_accessTokenKey);
      if (verifyToken != token) {
        print('Token changed during retrieval');
        return verifyToken;
      }

      // Verify user data exists
      final userData = _prefs.getString(_userKey);
      if (userData == null) {
        print('User data missing, clearing invalid token');
        await clearTokens();
        return null;
      }

      return token;
    } catch (e) {
      print('Error retrieving access token: $e');
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required Duration accessTokenDuration,
    User? user,
  }) async {
    print('Saving tokens to storage...');
    print('Access Token: ${accessToken.substring(0, 10)}...');
    print('Refresh Token: ${refreshToken.substring(0, 10)}...');
    print('User data provided: ${user != null}');

    try {
      // Save everything atomically
      final expiry = DateTime.now().add(accessTokenDuration);
      await Future.wait([
        _prefs.setString(_accessTokenKey, accessToken),
        _prefs.setString(_refreshTokenKey, refreshToken),
        _prefs.setString(_tokenExpiryKey, expiry.toIso8601String()),
        if (user != null) ...[
          _prefs.setString(_userKey, jsonEncode(user.toJson())),
          _prefs.setString(_roleKey, user.role),
        ],
      ]);

      // Verify the saved data
      final savedAccessToken = _prefs.getString(_accessTokenKey);
      final savedRefreshToken = _prefs.getString(_refreshTokenKey);
      final savedExpiry = _prefs.getString(_tokenExpiryKey);
      final savedUserData = user != null ? _prefs.getString(_userKey) : null;
      final savedRole = user != null ? _prefs.getString(_roleKey) : null;

      if (savedAccessToken != accessToken ||
          savedRefreshToken != refreshToken ||
          savedExpiry == null ||
          (user != null && (savedUserData == null || savedRole == null))) {
        print('Data verification failed after save');
        throw Exception('Data verification failed after save');
      }

      print('Tokens and user data saved and verified successfully');
    } catch (e) {
      print('Error saving data: $e');
      // Clear any partially saved data
      await clearTokens();
      throw Exception('Failed to save data: $e');
    }
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = _prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        print('No refresh token found');
        return null;
      }

      print(
          'Attempting to refresh token using refresh token: ${refreshToken.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/v1/user/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      print('Refresh token response status: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['token'];
        if (newToken != null) {
          // Save the new token with the same refresh token
          await saveTokens(
            accessToken: newToken,
            refreshToken: refreshToken, // Keep the same refresh token
            accessTokenDuration: const Duration(hours: 24),
          );
          return newToken;
        }
      }

      print('Token refresh failed');
      await clearTokens(); // Clear invalid tokens
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      await clearTokens(); // Clear tokens on error
      return null;
    }
  }

  Future<void> clearTokens() async {
    print('Clearing tokens');
    try {
      await Future.wait([
        _prefs.remove(_accessTokenKey),
        _prefs.remove(_refreshTokenKey),
        _prefs.remove(_tokenExpiryKey),
      ]);

      // Verify tokens are cleared
      final accessToken = _prefs.getString(_accessTokenKey);
      final refreshToken = _prefs.getString(_refreshTokenKey);
      final tokenExpiry = _prefs.getString(_tokenExpiryKey);

      if (accessToken != null || refreshToken != null || tokenExpiry != null) {
        print('Warning: Some tokens still exist after clearing');
        // Force clear if normal clear failed
        await _prefs.remove(_accessTokenKey);
        await _prefs.remove(_refreshTokenKey);
        await _prefs.remove(_tokenExpiryKey);
      } else {
        print('Tokens cleared successfully');
      }
    } catch (e) {
      print('Error clearing tokens: $e');
      // Attempt force clear
      await _prefs.clear();
      throw Exception('Failed to clear tokens: $e');
    }
  }

  User? getUser() {
    try {
      final userJson = _prefs.getString(_userKey);
      print('Retrieved user data: $userJson');
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        // Verify the role format using API's format
        if (user.role == 'serviceProvider' || user.role == 'serviceTaker') {
          return user;
        } else {
          print('Invalid role format in stored user data: ${user.role}');
          return null;
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  Future<void> saveUser(User user) async {
    try {
      // Verify we still have the token before saving user
      final token = _prefs.getString(_accessTokenKey);
      if (token == null) {
        print('ERROR: Token missing when saving user!');
        throw Exception('Token missing when saving user');
      }

      final userJson = jsonEncode(user.toJson());
      await _prefs.setString(_userKey, userJson);
      await _prefs.setString(_roleKey, user.role);
      print('Saved user data: $userJson');
      print('Saved role: ${user.role}');

      // Verify token still exists after saving user
      final finalToken = _prefs.getString(_accessTokenKey);
      print('Verified token still exists after saving user: $finalToken');
    } catch (e) {
      print('Error saving user data: $e');
      throw e;
    }
  }

  String? getUserRole() {
    final role = _prefs.getString(_roleKey);
    print('Retrieved role from storage: $role');

    // Verify role format - using API's format
    if (role != 'serviceProvider' && role != 'serviceTaker') {
      print('Invalid role format in storage: $role');
      return null;
    }

    return role;
  }

  bool isProvider() {
    final role = getUserRole();
    return role == 'serviceProvider'; // Match API format
  }

  bool isTaker() {
    final role = getUserRole();
    return role == 'serviceTaker'; // Match API format
  }

  bool validateStoredUser() {
    try {
      final token = _prefs.getString(_accessTokenKey);
      final user = getUser();
      final role = getUserRole();

      print('Validating stored user:');
      print(
          'Token: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
      print('User: ${user != null ? "exists" : "null"}');
      print('Role: $role');
      print('User role from object: ${user?.role}');

      if (token == null || user == null || role == null) {
        print('Missing required data');
        return false;
      }

      if (role != user.role ||
          (role != 'serviceProvider' && role != 'serviceTaker')) {
        print('Role mismatch or invalid format');
        return false;
      }

      print('User validation successful');
      return true;
    } catch (e) {
      print('Error validating stored user: $e');
      return false;
    }
  }

  Future<void> clearAll() async {
    final hasSeenGetStarted = _prefs.getBool(_hasSeenGetStartedKey);
    print('Clearing all data');
    await _prefs.clear();
    if (hasSeenGetStarted == true) {
      await _prefs.setBool(_hasSeenGetStartedKey, true);
    }
  }

  Future<String?> getName() async {
    return _prefs.getString('name');
  }

  Future<String?> getTokenForHeaders() async {
    print('Getting token for headers: ${await getAccessToken()}');
    return getAccessToken();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getTokenForHeaders();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      print('Final headers: {..., Authorization: Bearer $token}');
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
