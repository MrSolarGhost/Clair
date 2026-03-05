import 'emulator_adapter.dart';

class EmulatorRegistry {
  final EmulatorAdapter retroarch;

  EmulatorRegistry({required this.retroarch});

  EmulatorAdapter? forSystem(String system) {
    if (retroarch.supportedSystems.contains(system)) return retroarch;
    return null;
  }
}
