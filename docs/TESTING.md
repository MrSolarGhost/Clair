# Collections Persistence Testing Guide

This document provides manual testing procedures and automated test verification for the collections persistence feature.

## Automated Tests

### Running All Tests

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/services/collections_service_test.dart
flutter test test/screens/collections_screen_test.dart
flutter test test/screens/collection_editor_screen_test.dart
flutter test test/screens/collection_detail_screen_test.dart
```

### Test Coverage

#### CollectionsService Tests (`test/services/collections_service_test.dart`)
- ✅ Create collection with all fields
- ✅ Create collection with minimal fields
- ✅ Update collection
- ✅ Delete collection
- ✅ List collections
- ✅ Get collection by ID
- ✅ Add game to collection
- ✅ Remove game from collection
- ✅ Game count updates
- ✅ coverPath persistence and updates
- ✅ Error handling for invalid operations
- ✅ Null handling

#### CollectionsScreen Tests (`test/screens/collections_screen_test.dart`)
- ✅ Display title and subtitle
- ✅ Display New Collection button
- ✅ Show loading indicator
- ✅ Display collections in grid (3 columns)
- ✅ Show collection descriptions
- ✅ Show game counts
- ✅ Handle empty collections
- ✅ Navigation to editor
- ✅ Proper styling and layout
- ✅ Error handling

#### CollectionEditorScreen Tests (`test/screens/collection_editor_screen_test.dart`)
- ✅ Create mode title and button text
- ✅ Edit mode title and button text
- ✅ Form fields display
- ✅ Name field validation (required)
- ✅ Description field (optional)
- ✅ Cover image picker
- ✅ Pre-fill form in edit mode
- ✅ Delete confirmation dialog
- ✅ Loading states
- ✅ Layout and spacing
- ✅ Error handling

#### CollectionDetailScreen Tests (`test/screens/collection_detail_screen_test.dart`)
- ✅ Loading indicator
- ✅ Display collection name and description
- ✅ Display game count
- ✅ Back and edit buttons
- ✅ Empty state display
- ✅ Games grid (4 columns)
- ✅ Game cover placeholder
- ✅ Collection cover placeholder
- ✅ Null handling (description, system, etc.)
- ✅ Non-existent collection error
- ✅ Layout and gradient

## Manual Testing Procedures

### 1. Collection Creation

**Test:** Create a new collection

Steps:
1. Navigate to Collections tab
2. Click "New Collection" button
3. Enter name: "Test Collection"
4. Enter description: "This is a test"
5. (Optional) Click cover picker and select image
6. Click "Create Collection"

**Expected:**
- Form validates (name required)
- Navigation returns to Collections screen
- New collection appears in grid
- Collection shows "0 games"
- Cover displays if selected, otherwise shows icon

**Error Cases:**
- Submit without name → Shows "Name is required"
- Cancel file picker → No crash, no cover selected
- Network issues → Silent failure, stays on form

---

### 2. Collection Editing

**Test:** Edit an existing collection

Steps:
1. Navigate to Collections tab
2. Select a collection
3. In detail screen, click Edit icon (top right)
4. Change name to "Updated Collection"
5. Change description
6. Change cover image
7. Click "Save Changes"

**Expected:**
- Form pre-fills with existing data
- Updates persist to database
- Navigation returns to detail screen
- Changes reflected immediately

**Error Cases:**
- Clear name and submit → Validation error
- Database error → Silent failure, stays on form

---

### 3. Collection Deletion

**Test:** Delete a collection

Steps:
1. Navigate to Collections tab
2. Select a collection
3. Click Edit icon
4. Click Delete icon (top right)
5. Confirm deletion in dialog

**Expected:**
- Confirmation dialog appears
- Dialog shows warning about games not being deleted
- After confirm, returns to Collections screen
- Collection no longer appears in list
- Games remain in library

**Cancel Flow:**
- Click "Cancel" in dialog → Dialog dismisses, no deletion

---

### 4. Adding Games to Collection

**Test:** Add games to a collection

Steps:
1. Create a collection
2. Navigate to detail screen
3. (Manual implementation needed for game picker)
4. Add 3-4 games
5. Return to detail screen

**Expected:**
- Games appear in grid
- Game count updates ("4 games")
- Each game shows title, system, cover
- Grid maintains 4-column layout

---

### 5. Empty States

**Test:** Verify empty state displays

Steps:
1. Create a new collection
2. Open detail screen immediately

**Expected:**
- Shows "No games yet" message
- Shows collections icon
- No grid displayed
- Edit and back buttons still functional

---

### 6. Cover Image Handling

**Test:** Cover image persistence

Steps:
1. Create collection with cover image
2. Verify cover shows in Collections grid
3. Open detail screen
4. Verify cover shows in header
5. Edit collection and remove cover
6. Verify placeholder icon appears

**Expected:**
- Cover images persist across sessions
- Placeholders show when no cover set
- File picker only accepts images
- Invalid file paths handled silently

---

### 7. Keyboard Navigation

**Test:** Controller/keyboard navigation in collections

Steps:
1. Navigate to Collections tab
2. Use arrow keys to move selection
3. Press Enter/Space to open collection
4. In detail screen, use arrows to navigate games
5. Press Enter to open game card

**Expected:**
- Arrow keys move selection in grid
- Visual highlight follows selection
- Enter/Space opens selected item
- Grid wraps correctly at edges
- Selection state persists during navigation

---

### 8. Error Handling

**Test:** Graceful error handling

Scenarios:
1. Open non-existent collection ID
2. Database connection fails
3. File picker permission denied
4. Invalid cover image path
5. Concurrent modifications

**Expected:**
- No crashes or unhandled exceptions
- User-friendly error messages where appropriate
- Silent failures for minor issues
- Loading states clear properly
- Navigation remains functional

---

### 9. Performance

**Test:** Large collections

Steps:
1. Create collection with 50+ games
2. Scroll through grid
3. Navigate between screens
4. Edit collection details

**Expected:**
- Smooth scrolling (60 FPS)
- No lag when loading
- Images load progressively
- Memory usage reasonable
- No UI blocking

---

### 10. Data Persistence

**Test:** Data survives app restart

Steps:
1. Create 3 collections with covers
2. Add games to each
3. Restart app
4. Navigate to Collections tab

**Expected:**
- All collections persist
- Game counts correct
- Covers load correctly
- Descriptions intact
- Order maintained

---

## Test Execution Checklist

Before merging:

- [ ] All automated tests pass (`flutter test`)
- [ ] Manual test 1: Collection creation (success + errors)
- [ ] Manual test 2: Collection editing (success + errors)
- [ ] Manual test 3: Collection deletion (confirm + cancel)
- [ ] Manual test 4: Adding/removing games
- [ ] Manual test 5: Empty states display
- [ ] Manual test 6: Cover image handling
- [ ] Manual test 7: Keyboard navigation
- [ ] Manual test 8: Error handling scenarios
- [ ] Manual test 9: Performance with large collections
- [ ] Manual test 10: Data persistence after restart

## Known Limitations

1. Game picker UI not yet implemented (manual DB insertion for testing)
2. Cover image selection from game covers not yet implemented
3. Drag-and-drop reordering not implemented
4. Bulk operations not implemented
5. Search/filter not implemented

## Next Steps

After all tests pass:
1. Merge branch to main
2. Test on physical device
3. Implement game picker UI
4. Add search/filter functionality
5. Implement drag-and-drop reordering
