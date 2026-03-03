import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

/// Manages gamepad and keyboard input in a unified way
class InputService extends ChangeNotifier {
  final Set<String> _connectedGamepads = {};
  bool _hasGamepad = false;

  InputService() {
    _initializeGamepads();
  }

  bool get hasGamepad => _hasGamepad;

  void _initializeGamepads() {
    // Listen for gamepad connections
    Gamepads.events.listen((event) {
      if (event.runtimeType.toString() == 'GamepadConnectedEvent') {
        _connectedGamepads.add(event.gamepadId);
        _hasGamepad = true;
        notifyListeners();
        if (kDebugMode) {
          print('Gamepad connected: ${event.gamepadId}');
        }
      } else if (event.runtimeType.toString() == 'GamepadDisconnectedEvent') {
        _connectedGamepads.remove(event.gamepadId);
        _hasGamepad = _connectedGamepads.isNotEmpty;
        notifyListeners();
        if (kDebugMode) {
          print('Gamepad disconnected: ${event.gamepadId}');
        }
      }
    });
  }

  /// Handle keyboard navigation shortcuts
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.space:
        return true; // Handled by Focus widget
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _connectedGamepads.clear();
    super.dispose();
  }
}
