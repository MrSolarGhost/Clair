import 'package:clair/models/guide.dart';
import 'package:clair/screens/guide_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('restores scroll position per guide', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guides.scroll.1': 120.0,
    });

    final guide = Guide(
      id: 1,
      title: 'Test Guide',
      type: GuideType.text,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: GuideDetailScreen(guide: guide)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, greaterThanOrEqualTo(120.0));
  });

  testWidgets('ignores scroll restore when id is null', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guides.scroll.1': 200.0,
    });

    final guide = Guide(
      id: null,
      title: 'No ID',
      type: GuideType.text,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: GuideDetailScreen(guide: guide)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, 0.0);
  });
}
