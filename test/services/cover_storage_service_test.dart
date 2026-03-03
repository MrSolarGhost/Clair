import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clair/services/cover_storage_service.dart';

void main() {
  group('CoverStorageService', () {
    test('downloadCover returns null on network failure', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = CoverStorageService(client: mockClient);
      final path = await service.downloadCover(
        'https://example.com/cover.jpg',
        gameId: 123,
      );

      expect(path, isNull);
    });

    test('downloadCover returns null on non-200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not found', 404);
      });

      final service = CoverStorageService(client: mockClient);
      final path = await service.downloadCover(
        'https://example.com/cover.jpg',
        gameId: 123,
      );

      expect(path, isNull);
    });
  });
}
