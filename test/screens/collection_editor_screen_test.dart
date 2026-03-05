import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/screens/collection_editor_screen.dart';
import 'package:clair/models/collection.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late DatabaseService dbService;
  late CollectionsService service;

  setUp(() async {
    dbService = DatabaseService.instance;
    await dbService.database;
    service = CollectionsService();

    // Clean up
    final db = await dbService.database;
    await db.delete('collections');
  });

  Future<void> pumpEditorScreen(
    WidgetTester tester, {
    Collection? collection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionEditorScreen(collection: collection),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CollectionEditorScreen Widget Tests - Create Mode', () {
    testWidgets('displays correct title for new collection', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.text('New Collection'), findsOneWidget);
    });

    testWidgets('displays all form fields', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Collection Name'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
    });

    testWidgets('displays cover picker', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.text('Add Cover'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('displays create button', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.text('Create Collection'), findsOneWidget);
    });

    testWidgets('does not show delete button in create mode', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('name field is required', (tester) async {
      await pumpEditorScreen(tester);

      // Try to submit without entering name
      await tester.tap(find.text('Create Collection'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('description field is optional', (tester) async {
      await pumpEditorScreen(tester);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test Collection');

      // Submit without description
      await tester.tap(find.text('Create Collection'));
      await tester.pumpAndSettle();

      // Should not show validation error for description
      expect(find.text('Name is required'), findsNothing);
    });

    testWidgets('can enter collection name', (tester) async {
      await pumpEditorScreen(tester);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'My Collection');
      await tester.pumpAndSettle();

      expect(find.text('My Collection'), findsOneWidget);
    });

    testWidgets('can enter description', (tester) async {
      await pumpEditorScreen(tester);

      final descField = find.byType(TextFormField).at(1);
      await tester.enterText(descField, 'My description');
      await tester.pumpAndSettle();

      expect(find.text('My description'), findsOneWidget);
    });

    testWidgets('description field allows multiple lines', (tester) async {
      await pumpEditorScreen(tester);

      final descField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );

      expect(descField.maxLines, 3);
    });
  });

  group('CollectionEditorScreen Widget Tests - Edit Mode', () {
    testWidgets('displays correct title for edit', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      expect(find.text('Edit Collection'), findsOneWidget);
    });

    testWidgets('displays delete button in edit mode', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('displays save changes button in edit mode', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('pre-fills form with collection data', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Existing Collection',
        description: 'Existing description',
        createdDate: DateTime.now(),
        gameCount: 5,
      );

      await pumpEditorScreen(tester, collection: collection);

      expect(find.text('Existing Collection'), findsOneWidget);
      expect(find.text('Existing description'), findsOneWidget);
    });

    testWidgets('pre-fills form with null description', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        description: null,
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      final descField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(descField.controller?.text, '');
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Collection'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this collection? Games will not be deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel delete dialog dismisses', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Delete Collection'), findsNothing);
    });
  });

  group('CollectionEditorScreen Cover Image', () {
    testWidgets('displays placeholder when no cover', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.text('Add Cover'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('cover picker is tappable', (tester) async {
      await pumpEditorScreen(tester);

      final coverPicker = find.ancestor(
        of: find.text('Add Cover'),
        matching: find.byType(GestureDetector),
      );

      expect(coverPicker, findsOneWidget);
    });

    testWidgets('cover container has correct size', (tester) async {
      await pumpEditorScreen(tester);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Add Cover'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 200);
      expect(container.constraints?.maxHeight, 200);
    });
  });

  group('CollectionEditorScreen Error Handling', () {
    testWidgets('handles empty name validation', (tester) async {
      await pumpEditorScreen(tester);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '   '); // Just whitespace

      await tester.tap(find.text('Create Collection'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows loading indicator during save', (tester) async {
      await pumpEditorScreen(tester);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test');

      await tester.tap(find.text('Create Collection'));
      await tester.pump(); // Don't settle, check intermediate state

      // Loading state should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables delete button during loading', (tester) async {
      final collection = Collection(
        id: 1,
        name: 'Test',
        createdDate: DateTime.now(),
        gameCount: 0,
      );

      await pumpEditorScreen(tester, collection: collection);

      // Trigger save to enter loading state
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      final deleteButton = tester.widget<IconButton>(
        find.byIcon(Icons.delete),
      );
      expect(deleteButton.onPressed, isNull);
    });
  });

  group('CollectionEditorScreen Layout', () {
    testWidgets('uses SingleChildScrollView', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses Form widget', (tester) async {
      await pumpEditorScreen(tester);

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has proper spacing between elements', (tester) async {
      await pumpEditorScreen(tester);

      // Check for SizedBox spacing
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);
    });

    testWidgets('save button spans full width', (tester) async {
      await pumpEditorScreen(tester);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Collection'),
      );

      // Check button has vertical padding
      expect(button.style?.padding?.resolve({}), isNotNull);
    });
  });
}
