import '../models/game.dart';

abstract class EmulatorAdapter {
  List<String> get supportedSystems;
  Future<bool> validate();
  Future<void> launch(Game game);
}
