import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game.dart';
import 'emulator_registry.dart';
import 'retroarch_adapter.dart';

class EmulatorLaunchService {
  Future<void> launch(Game game) async {
    final retroarchPath = dotenv.env['RETROARCH_PATH'] ?? '';
    final coresPath = dotenv.env['RETROARCH_CORES_PATH'] ?? '';
    if (retroarchPath.isEmpty || coresPath.isEmpty) {
      throw Exception('RetroArch not configured');
    }

    final registry = EmulatorRegistry(
      retroarch: RetroArchAdapter(
        executablePath: retroarchPath,
        corePath: coresPath,
      ),
    );

    final system = game.system ?? '';
    final adapter = registry.forSystem(system);
    if (adapter == null) {
      throw Exception('No emulator configured for system');
    }

    final ok = await adapter.validate();
    if (!ok) {
      throw Exception('RetroArch path invalid');
    }

    await adapter.launch(game);
  }
}
