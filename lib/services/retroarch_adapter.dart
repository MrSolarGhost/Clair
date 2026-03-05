import 'dart:io';
import '../models/game.dart';
import 'core_matrix.dart';
import 'emulator_adapter.dart';

class RetroArchAdapter implements EmulatorAdapter {
  final String executablePath;
  final String corePath;

  RetroArchAdapter({required this.executablePath, required this.corePath});

  @override
  List<String> get supportedSystems => CoreMatrix.systems.keys.toList();

  @override
  Future<bool> validate() async {
    return File(executablePath).exists();
  }

  List<String> buildArgs(Game game) {
    final core = CoreMatrix.coreForSystem(game.system ?? '');
    if (core == null) return [];
    return ['-L', '$corePath/${core}_libretro.so', game.executablePath ?? ''];
  }

  @override
  Future<void> launch(Game game) async {
    if (game.executablePath == null) {
      throw Exception('Missing ROM path');
    }
    final args = buildArgs(game);
    await Process.start(executablePath, args);
  }
}
