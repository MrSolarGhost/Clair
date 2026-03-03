import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clair/services/steamgriddb_service.dart';

void main() {
  group('SteamGridDBService', () {
    test('search returns game results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "data": [{"id": 123, "name": "Test Game"}]}',
          200,
        );
      });

      final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
      final results = await service.search('Test Game');

      expect(results, isNotEmpty);
      expect(results.first['id'], 123);
      expect(results.first['name'], 'Test Game');
    });

    test('search handles timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(Duration(seconds: 5));
        return http.Response('{}', 200);
      });

      final service = SteamGridDBService(
        client: mockClient,
        apiKey: 'test-key',
        timeout: Duration(seconds: 2),
      );

      expect(
        () => service.search('Test Game'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
