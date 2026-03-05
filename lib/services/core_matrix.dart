class CoreMatrix {
  static const Map<String, Map<String, dynamic>> systems = {
    'NES': {'core': 'nestopia', 'extensions': ['nes']},
    'SNES': {'core': 'snes9x', 'extensions': ['sfc', 'smc']},
    'GB': {'core': 'gambatte', 'extensions': ['gb']},
    'GBC': {'core': 'gambatte', 'extensions': ['gbc']},
    'GBA': {'core': 'mgba', 'extensions': ['gba']},
    'PS1': {'core': 'pcsx_rearmed', 'extensions': ['cue', 'bin', 'iso']},
  };

  static String? coreForSystem(String system) => systems[system]?['core'] as String?;
  static List<String> extensionsForSystem(String system) =>
      List<String>.from(systems[system]?['extensions'] ?? []);
}
