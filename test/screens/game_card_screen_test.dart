import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:clair/screens/game_card_screen.dart';

void main() {
  testWidgets('GameCardScreen renders title and status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameCardScreen(gameId: 1),
      ),
    );

    // Expect placeholders until data loads
    expect(find.textContaining('Loading'), findsOneWidget);
  });
}
