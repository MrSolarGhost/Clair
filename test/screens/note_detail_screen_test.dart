import 'package:clair/models/note.dart';
import 'package:clair/screens/note_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('restores scroll position per note', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notes.scroll.1': 120.0,
    });

    final note = Note(
      id: 1,
      title: 'Test Note',
      content: 'Line\n' * 200,
      type: NoteType.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteDetailScreen(note: note)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, greaterThanOrEqualTo(120.0));
  });

  testWidgets('ignores scroll restore when id is null', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notes.scroll.1': 200.0,
    });

    final note = Note(
      id: null,
      title: 'No ID',
      content: 'Short note',
      type: NoteType.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteDetailScreen(note: note)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, 0.0);
  });
}
