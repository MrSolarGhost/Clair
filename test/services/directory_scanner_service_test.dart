import 'package:flutter_test/flutter_test.dart';
import 'package:clair/services/directory_scanner_service.dart';

void main() {
  group('DirectoryScannerService', () {
    late DirectoryScannerService service;

    setUp(() {
      service = DirectoryScannerService();
    });

    test('parseTitle removes extension and formats title', () {
      expect(service.parseTitle('atelier-ryza.vpk'), 'Atelier Ryza');
      expect(service.parseTitle('sonic_adventure_2.iso'), 'Sonic Adventure 2');
      expect(service.parseTitle('mario.kart.8.nsp'), 'Mario Kart 8');
      expect(service.parseTitle('ZELDA_BOTW.xci'), 'Zelda Botw');
    });

    test('isGameFile filters supported extensions', () {
      // Supported
      expect(service.isGameFile('game.vpk'), true);
      expect(service.isGameFile('game.iso'), true);
      expect(service.isGameFile('game.exe'), true);
      
      // Not supported
      expect(service.isGameFile('readme.txt'), false);
      expect(service.isGameFile('cover.jpg'), false);
      expect(service.isGameFile('game.nfo'), false);
    });
  });
}
