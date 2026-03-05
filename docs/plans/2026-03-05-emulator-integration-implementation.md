# Emulator Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Add a RetroArch-first emulator abstraction so users can select a game and launch it.

**Architecture:** Introduce an EmulatorAdapter interface, RetroArchAdapter, registry, and core matrix for NES/SNES/GB/GBC/GBA/PS1. Add settings to configure RetroArch per OS and connect GameCard launch to the registry.

**Tech Stack:** Flutter, Dart, sqflite

---

### Task 1: Add failing tests for core matrix

**Files:**
- Create: `test/services/core_matrix_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:clair/services/core_matrix.dart';

void main() {
  test('core matrix maps system to core', () {
    expect(CoreMatrix.coreForSystem('SNES'), isNotNull);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/core_matrix_test.dart`
Expected: FAIL with "CoreMatrix not found"

**Step 3: Commit**

```bash
git add test/services/core_matrix_test.dart
git commit -m "test: add core matrix placeholder test"
```

---

### Task 2: Implement core matrix config

**Files:**
- Create: `lib/services/core_matrix.dart`

**Step 1: Implement minimal CoreMatrix**

```dart
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
```

**Step 2: Run test to verify it passes**

Run: `flutter test test/services/core_matrix_test.dart`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/services/core_matrix.dart
git commit -m "feat(core): add retroarch core matrix"
```

---

### Task 3: Add emulator adapter interface

**Files:**
- Create: `lib/services/emulator_adapter.dart`

**Step 1: Implement interface**

```dart
import '../models/game.dart';

abstract class EmulatorAdapter {
  List<String> get supportedSystems;
  Future<bool> validate();
  Future<void> launch(Game game);
}
```

**Step 2: Commit**

```bash
git add lib/services/emulator_adapter.dart
git commit -m "feat(emulator): add adapter interface"
```

---

### Task 4: Add RetroArch adapter

**Files:**
- Create: `lib/services/retroarch_adapter.dart`
- Modify: `lib/services/core_matrix.dart`
- Create: `test/services/retroarch_adapter_test.dart`

**Step 1: Write failing test for command build**

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/retroarch_adapter_test.dart`
Expected: FAIL with "RetroArchAdapter not found"

**Step 3: Implement RetroArchAdapter**

```dart
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
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/retroarch_adapter_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/retroarch_adapter.dart lib/services/core_matrix.dart test/services/retroarch_adapter_test.dart
git commit -m "feat(emulator): add retroarch adapter"
```

---

### Task 5: Add emulator registry

**Files:**
- Create: `lib/services/emulator_registry.dart`

**Step 1: Implement registry**

```dart
import 'emulator_adapter.dart';
import 'retroarch_adapter.dart';

class EmulatorRegistry {
  final EmulatorAdapter retroarch;

  EmulatorRegistry({required this.retroarch});

  EmulatorAdapter? forSystem(String system) {
    if (retroarch.supportedSystems.contains(system)) return retroarch;
    return null;
  }
}
```

**Step 2: Commit**

```bash
git add lib/services/emulator_registry.dart
git commit -m "feat(emulator): add registry"
```

---

### Task 6: Add Settings for RetroArch paths

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Step 1: Add fields to configure RetroArch executable path and core path**

Add two text fields below the SteamGridDB key:
- RetroArch executable path
- RetroArch cores path

Store in `.env` via the same save logic, using keys:
- `RETROARCH_PATH`
- `RETROARCH_CORES_PATH`

**Step 2: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat(settings): add retroarch config fields"
```

---

### Task 7: Wire GameCard launch to emulator registry

**Files:**
- Modify: `lib/screens/game_card_screen.dart`
- Create: `lib/services/emulator_launch_service.dart`

**Step 1: Add launch service**

```dart
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
```

**Step 2: Update GameCardScreen**

Replace `_mockLaunch` with:

```dart
  Future<void> _launch(Game game) async {
    try {
      await EmulatorLaunchService().launch(game);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
```

Update the Launch button to call `_launch(game)`.

**Step 3: Commit**

```bash
git add lib/services/emulator_launch_service.dart lib/screens/game_card_screen.dart
git commit -m "feat(launch): wire game card to emulator registry"
```

---

### Task 8: Update docs

**Files:**
- Modify: `docs/screens/game-card.md`
- Modify: `README.md`

**Step 1: Document RetroArch setup requirements**

Add a short section with:
- install RetroArch
- set `RETROARCH_PATH` and `RETROARCH_CORES_PATH` in Settings
- supported systems list (v1)

**Step 2: Commit**

```bash
git add docs/screens/game-card.md README.md
git commit -m "docs: add retroarch setup"
```
