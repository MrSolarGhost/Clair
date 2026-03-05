import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:clair/screens/game_card_screen.dart';

void main() {
  testWidgets('GameCardScreen renders loading state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameCardScreen(gameId: 1),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
