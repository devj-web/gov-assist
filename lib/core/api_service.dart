
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Chrome / Flutter Web on the same PC.
  // Android emulator: http://10.0.2.2:8000
  static const String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000'
      : 'http://10.0.2.2:8000';

  static String? token;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data is Map ? data['detail'] ?? 'Login failed' : 'Login failed',
      );
    }

    token = data['access_token'] as String?;
    if (token == null) {
      throw Exception('Login response did not contain an access token');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    return _decode(response);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query,
    );

    final response = await http.patch(
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['detail'] ?? 'Request failed'
          : 'Request failed (${response.statusCode})';
      throw Exception(message);
    }

    return data;
  }
}
