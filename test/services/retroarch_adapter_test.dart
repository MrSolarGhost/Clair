import 'package:flutter_test/flutter_test.dart';
import 'package:clair/services/retroarch_adapter.dart';
import 'package:clair/models/game.dart';

void main() {
  test('RetroArchAdapter builds command args', () async {
    final adapter = RetroArchAdapter(
      executablePath: '/usr/bin/retroarch',
      corePath: '/cores',
    );

    final game = Game(title: 'Test', system: 'SNES', executablePath: '/roms/test.sfc');
    final args = adapter.buildArgs(game);

    expect(args, contains('/cores/snes9x_libretro.so'));
    expect(args, contains('/roms/test.sfc'));
  });
}
