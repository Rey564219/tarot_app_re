import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl});

  static const _requestTimeout = Duration(seconds: 12);
  final String baseUrl;
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _sendWithTimeout(
      () => http.get(Uri.parse('$baseUrl$path'), headers: _headers()),
      '$baseUrl$path',
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final response = await _sendWithTimeout(
      () => http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: jsonEncode(body),
      ),
      '$baseUrl$path',
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postJsonWithHeaders(
    String path,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    final response = await _sendWithTimeout(
      () => http.post(
        Uri.parse('$baseUrl$path'),
        headers: {..._headers(), ...headers},
        body: jsonEncode(body),
      ),
      '$baseUrl$path',
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _sendWithTimeout(
      () => http.get(Uri.parse('$baseUrl$path'), headers: _headers()),
      '$baseUrl$path',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(_decodeBody(response));
      if (decoded is List) {
        return decoded;
      }
      throw Exception('Expected list response');
    }
    throw Exception('HTTP ${response.statusCode}: ${_decodeBody(response)}');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(_decodeBody(response));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Expected object response');
    }
    throw Exception('HTTP ${response.statusCode}: ${_decodeBody(response)}');
  }

  String _decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Future<http.Response> _sendWithTimeout(
    Future<http.Response> Function() request,
    String uri,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Request timeout after ${_requestTimeout.inSeconds}s: $uri');
    }
  }
}
