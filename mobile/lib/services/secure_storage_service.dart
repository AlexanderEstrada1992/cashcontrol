import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'cashcontrol.access_token';
  static const _refreshTokenKey = 'cashcontrol.refresh_token';
  static const _userIdKey = 'cashcontrol.user_id';
  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}