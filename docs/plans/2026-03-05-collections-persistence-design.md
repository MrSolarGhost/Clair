# Collections Persistence Design

## Goal
Replace mock collections with SQLite-backed collections, artwork support, and a dedicated collection editor.

## Selected Approach
SQLite-backed collections with a dedicated CollectionEditorScreen. Artwork stored as file path in the database.

## Architecture
- Use existing `collections` and `collection_games` tables.
- Add `coverPath` column to `collections`.
- CollectionsService wraps DatabaseService for CRUD + membership updates.
- CollectionsScreen reads collections from DB.
- CollectionEditorScreen handles create/edit, artwork selection, and game membership.

## Components
- **CollectionsService** (new): create/update/delete collections, add/remove games, load collection detail.
- **CollectionEditorScreen** (new): name/description, artwork picker, game selector.
- **CollectionsScreen**: use DB-backed collections.
- **CollectionDetailScreen**: show collection games + artwork.

## Data Flow
1. User taps “New Collection” → CollectionEditorScreen.
2. Save creates collection in DB and optional coverPath.
3. Add/remove games writes to `collection_games`.
4. CollectionsScreen queries collections + counts.
5. CollectionDetailScreen loads games by collection.

## Error Handling
- Missing artwork file → fall back to default placeholder.
- Empty collection → show empty state.
- Duplicate collection name → warn and block save.

## Testing
- Service tests for create/update/delete and add/remove games.
- Widget test for CollectionsScreen empty state.

## Notes
- Artwork sources: file picker or select from game covers.
- File storage: save under app documents and store path in `coverPath`.
