import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const _devUserId = String.fromEnvironment('DEV_USER_ID', defaultValue: '');
  static const _devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN', defaultValue: '');

  final ApiClient api = ApiClient(baseUrl: _resolveBaseUrl());

  static String _resolveBaseUrl() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }
    const androidDeviceBaseUrl = String.fromEnvironment(
      'ANDROID_DEVICE_API_BASE_URL',
      defaultValue: '',
    );
    if (androidDeviceBaseUrl.isNotEmpty) {
      return androidDeviceBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorBaseUrl;
    }
    return _defaultBaseUrl;
  }

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
    try {
      final hasDevUserOnly = _devUserId.isNotEmpty && _devAuthToken.isEmpty;
      if (hasDevUserOnly) {
        throw Exception(
          'DEV_USER_ID is set but DEV_AUTH_TOKEN is empty. '
          'Pass --dart-define=DEV_AUTH_TOKEN=<token> to use /auth/dev.',
        );
      }

      final hasDevAuthConfig = _devUserId.isNotEmpty && _devAuthToken.isNotEmpty;
      if (hasDevAuthConfig) {
        await _bootstrapAuth(prefs);
      } else if (_token == null) {
        await _bootstrapAuth(prefs);
      } else {
        api.setToken(_token!);
      }
    } catch (error) {
      throw Exception(_buildBootstrapErrorMessage(error));
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

  String _buildBootstrapErrorMessage(Object error) {
    final hint = <String>[
      '接続先: ${api.baseUrl}',
      '接続に失敗しました。バックエンド起動状況を確認してください。',
    ];

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      hint.add(
        'Android 実機で起動している場合は '
        '--dart-define=API_BASE_URL=http://<PCのIPアドレス>:8000 '
        'を指定して再実行してください。',
      );
    }

    return '$error\n\n${hint.join('\n')}';
  }
}
