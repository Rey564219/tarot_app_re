import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );
  static const _devUserId = String.fromEnvironment('DEV_USER_ID', defaultValue: '');
  static const _devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN', defaultValue: '');

  final ApiClient api = ApiClient(baseUrl: _baseUrl);

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
    if (_token == null) {
      await _bootstrapAuth(prefs);
    } else {
      api.setToken(_token!);
    }
  }

  Future<void> _bootstrapAuth(SharedPreferences prefs) async {
    if (_devUserId.isNotEmpty && _devAuthToken.isNotEmpty) {
      final response = await api.postJsonWithHeaders(
        '/auth/dev',
        {'user_id': _devUserId},
        {'X-Dev-Token': _devAuthToken},
      );
      _token = response['token'] as String?;
      _userId = response['user_id'] as String?;
    } else {
      final response = await api.postJson('/auth/anonymous', {});
      _token = response['token'] as String?;
      _userId = response['user_id'] as String?;
    }
    if (_token == null || _userId == null) {
      throw Exception('Auth bootstrap failed');
    }
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userIdKey, _userId!);
    api.setToken(_token!);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _token = null;
    _userId = null;
    api.setToken('');
  }

  static String prettyJson(Object? value) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(value);
  }
}
