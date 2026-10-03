import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/api_errors.dart';
import 'package:mobile/services/secure_storage_service.dart';

void main() {
  test('returns successful responses through the injected transport', () async {
    final client = ApiClient(
      baseUrl: 'https://cashcontrol.test',
      storage: _MemoryStorage(),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-old');
        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await client.get('/api/gastos');

    expect(response.statusCode, 200);
    expect(jsonDecode(response.body)['success'], isTrue);
  });

  test(
    'renews credentials after 401 and retries the original request once',
    () async {
      final storage = _MemoryStorage();
      var expenseRequests = 0;
      final client = ApiClient(
        baseUrl: 'https://cashcontrol.test',
        storage: storage,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/refresh') {
            expect(jsonDecode(request.body), {'refreshToken': 'refresh-old'});
            return http.Response(
              jsonEncode({
                'accessToken': 'access-new',
                'refreshToken': 'refresh-new',
                'userId': 'internal-user-7',
              }),
              200,
            );
          }
          expenseRequests++;
          if (expenseRequests == 1) return http.Response('{}', 401);
          expect(request.headers['Authorization'], 'Bearer access-new');
          return http.Response('{"data":[]}', 200);
        }),
      );

      final response = await client.get('/api/gastos');

      expect(response.statusCode, 200);
      expect(expenseRequests, 2);
      expect(storage.accessToken, 'access-new');
      expect(storage.refreshToken, 'refresh-new');
    },
  );

  test('maps 422 responses to field validation errors', () async {
    final client = ApiClient(
      baseUrl: 'https://cashcontrol.test',
      storage: _MemoryStorage(),
      client: MockClient(
        (_) async =>
            http.Response('{"errors":{"amount":"Monto inválido"}}', 422),
      ),
    );

    await expectLater(
      client.get('/api/gastos'),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.fieldErrors['amount'],
          'amount error',
          'Monto inválido',
        ),
      ),
    );
  });

  test('maps an exhausted request timeout to NetworkFailure', () async {
    final client = ApiClient(
      baseUrl: 'https://cashcontrol.test',
      storage: _MemoryStorage(),
      client: MockClient((_) => Completer<http.Response>().future),
      receiveTimeout: const Duration(milliseconds: 5),
    );

    await expectLater(
      client.get('/api/gastos'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}

class _MemoryStorage extends SecureStorageService {
  String? accessToken = 'access-old';
  String? refreshToken = 'refresh-old';
  String? userId = 'internal-user-7';

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.userId = userId;
  }

  @override
  Future<void> clearCredentials() async {
    accessToken = null;
    refreshToken = null;
    userId = null;
  }
}
