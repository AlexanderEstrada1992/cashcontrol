import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/secure_storage_service.dart';

void main() {
  test('sync watermark comes from backend X-Server-Time, including an empty list', () async {
    final storage = _TestStorage();
    final api = ApiService(client: ApiClient(
      baseUrl: 'http://localhost',
      storage: storage,
      client: MockClient((_) async => http.Response(
        '{"success":true,"data":[]}',
        200,
        headers: {'X-Server-Time': '2026-10-03T12:30:00.000Z'},
      )),
    ));

    final snapshot = await api.fetchExpenseSnapshot('user-1');

    expect(snapshot.expenses, isEmpty);
    expect(snapshot.syncedAt, DateTime.utc(2026, 10, 3, 12, 30));
  });
}

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;
}
