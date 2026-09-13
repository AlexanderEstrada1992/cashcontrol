import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_errors.dart';
import 'secure_storage_service.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.storage,
    this.onTokenRefreshed,
    http.Client? client,
    this.connectTimeout = const Duration(seconds: 8),
    this.receiveTimeout = const Duration(seconds: 8),
    this.sendTimeout = const Duration(seconds: 8),
  }) : _client = client ?? IOClient(HttpClient()..connectionTimeout = connectTimeout) {
    if (kReleaseMode && baseUrl.startsWith('http://')) {
      throw StateError('La API de producción debe utilizar HTTPS.');
    }
  }

  final String baseUrl;
  final SecureStorageService storage;
  final VoidCallback? onTokenRefreshed;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final http.Client _client;
  Future<bool>? _refreshing;

  Future<http.Response> get(String path, {Map<String, String>? queryParameters, bool authenticated = true}) =>
      _send('GET', path, queryParameters: queryParameters, authenticated: authenticated);

  Future<http.Response> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
    required bool authenticated,
    bool retried = false,
    bool networkRetried = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await storage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final started = DateTime.now();
    try {
      final response = await _request(method, uri, headers, body);
      if (kDebugMode) {
        debugPrint('$method $path -> ${response.statusCode} (${DateTime.now().difference(started).inMilliseconds}ms)');
      }
      if (response.statusCode == 401 && authenticated && !retried) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await _send(method, path, queryParameters: queryParameters, body: body, authenticated: authenticated, retried: true, networkRetried: networkRetried);
        }
        throw const AuthenticationFailure();
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return response;
      throw _mapFailure(response);
    } on AppApiException {
      rethrow;
    } catch (error) {
      if (error is TimeoutException || error is SocketException || error is http.ClientException) {
        if (method == 'GET' && !networkRetried) {
          return await _send(method, path, queryParameters: queryParameters, body: body, authenticated: authenticated, retried: retried, networkRetried: true);
        }
        throw const NetworkFailure();
      }
      rethrow;
    }
  }

  Future<http.Response> _request(String method, Uri uri, Map<String, String> headers, Object? body) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(receiveTimeout);
      case 'POST':
        return _client.post(uri, headers: headers, body: encoded).timeout(sendTimeout);
      default:
        throw UnsupportedError(method);
    }
  }

  Future<bool> _refreshToken() async {
    _refreshing ??= _performRefresh();
    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(sendTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await storage.clearCredentials();
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await storage.saveSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: data['userId'] as String,
      );
      onTokenRefreshed?.call();
      return true;
    } catch (_) {
      await storage.clearCredentials();
      return false;
    }
  }

  AppApiException _mapFailure(http.Response response) {
    if (response.statusCode == 401) return const AuthenticationFailure();
    if (response.statusCode == 422) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawErrors = data['errors'] as Map<String, dynamic>? ?? const {};
      return ValidationFailure(rawErrors.map((key, value) => MapEntry(key, value.toString())));
    }
    if (response.statusCode >= 500) return const ServerFailure();
    return HttpFailure('HTTP ${response.statusCode}');
  }
}
