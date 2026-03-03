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

    test('getCovers returns cover URLs', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "data": [{"id": 1, "url": "https://example.com/cover.jpg", "score": 10}]}',
          200,
        );
      });

      final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
      final covers = await service.getCovers(123);

      expect(covers, isNotEmpty);
      expect(covers.first['url'], 'https://example.com/cover.jpg');
      expect(covers.first['score'], 10);
    });

    test('getCovers sorts by score', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "data": [{"id": 1, "score": 5}, {"id": 2, "score": 10}, {"id": 3, "score": 8}]}',
          200,
        );
      });

      final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
      final covers = await service.getCovers(123);

      expect(covers[0]['score'], 10); // Highest first
      expect(covers[1]['score'], 8);
      expect(covers[2]['score'], 5);
    });
  });
}
