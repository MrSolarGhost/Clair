# SteamGridDB Integration Design

**Date:** 2026-03-02  
**Status:** Approved  
**Goal:** Auto-fetch game covers from SteamGridDB with manual override capability

---

## Overview

Add SteamGridDB integration to automatically fetch game cover art when games are added to the library. Support manual cover selection per game and batch operations for existing games without covers.

---

## Architecture

### New Components

**1. SteamGridDBService** (`lib/services/steamgriddb_service.dart`)
- API communication (search games, fetch cover URLs)
- Timeout handling (2-3 second quick fetch for auto operations)
- Result parsing and sorting by popularity/rating
- API key validation

**2. CoverFetchQueue** (`lib/services/cover_fetch_queue.dart`)
- Background queue for failed/retry fetches
- Processes queue when app is idle
- Updates game covers when downloads complete
- Persistent queue (survives app restarts via SQLite)
- Exponential backoff retry logic (1min, 5min, 15min, then give up)

**3. CoverStorageService** (`lib/services/cover_storage_service.dart`)
- Download covers from URLs
- Save to app documents directory
- Generate local file paths
- Clean up old covers when replaced

### Integration Points

- `DatabaseService` - stores cover paths (existing `coverPath` field)
- Game add flow - calls SteamGridDB after save
- Settings screen - API key input + batch operations
- Game detail screen - "Change cover" action

### Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0  # HTTP requests
  flutter_dotenv: ^5.1.0  # .env file handling
  path_provider: ^2.1.1  # Already present
```

---

## User Flows

### 1. Auto-Fetch on Game Add

```
User adds game → Game saved to database → SteamGridDBService.quickFetch()
  ├─ Success (< 3s): Download cover, update game, show in UI
  └─ Timeout/Failure: Add to queue, show placeholder

Background queue processes retry when app idle
```

**Behavior:**
- Non-blocking (game appears immediately with placeholder if needed)
- 2-3 second timeout for quick fetch
- Failed fetches queued for background retry
- No UI interruption

### 2. Manual "Change Cover" Per Game

```
User taps "Change cover" → SteamGridDBService.search() (no timeout)
  → Show picker UI with cover options
  → User selects cover
  → Download and update game
  → UI refreshes
```

**Behavior:**
- Controller-navigable picker UI
- Shows all available covers for the game
- Grid layout with preview images
- Cancel option to keep current cover

### 3. Batch "Get Game Covers"

```
User taps "Get game covers" in settings
  → Find all games with null coverPath
  → Add all to CoverFetchQueue
  → Show progress indicator
  → Queue processes, UI updates as covers arrive
```

**Behavior:**
- Progress indicator shows X/Y games processed
- Non-blocking (user can navigate away)
- Continues in background
- Notification when complete

---

## API Integration

### SteamGridDB API

**Search Endpoint:**
```
GET /search/autocomplete/{game_name}
```

**Get Covers:**
```
GET /grids/game/{game_id}?dimensions=600x900
```
- Use portrait covers (600x900)
- Sort results by `score` or `downloads` (popularity)
- Auto-select highest-rated cover for auto-fetch
- Return all results for manual picker

**Rate Limits:**
- API key allows 500 requests/hour
- Implement basic rate limiting in service
- Queue requests if approaching limit

**Search Strategy:**
1. Exact title match
2. If no results, try fuzzy search
3. If multiple results, filter by system/platform
4. Auto-select best result (highest score)
5. Fallback: queue for manual selection

---

## API Key Management

### Configuration Flow

**Settings Screen:**
- Input field for API key (obscured text)
- "Save" button
- Validation on save (non-empty string)
- Success/error feedback

**Storage:**
- Write to `.env` file in app documents directory
- Format: `STEAMGRIDDB_API_KEY=your_key_here`
- Create `.env` if doesn't exist
- Update existing line if file exists

**Loading:**
- Load on app start with `flutter_dotenv`
- Service reads key from environment
- If missing, operations fail gracefully with error message

**Setup Files:**
- Add `.env` to `.gitignore`
- Include `.env.example` with instructions:
  ```
  # SteamGridDB API Key
  # Get your key from: https://www.steamgriddb.com/profile/preferences/api
  STEAMGRIDDB_API_KEY=your_key_here
  ```

---

## Error Handling

### API Key Missing
- Service checks for key before requests
- Show error: "Add SteamGridDB API key in settings to fetch covers"
- Skip auto-fetch gracefully
- Manual operations show setup prompt

### Network Failures
- Quick fetch timeout (2-3s) → queue for retry
- Queue retry logic: exponential backoff (1min, 5min, 15min)
- After 3 retries, mark as failed and stop
- User can manually retry via "Change cover"

### No Results Found
- Try fuzzy matching if exact search fails
- Mark as "no cover available" if still empty
- Don't retry endlessly
- User can manually search with different terms

### Multiple Games, Same Title
- Platform/system filter helps
- Auto-select first result (user can change later)
- Manual picker shows all options

### Storage Full
- Catch disk space errors
- Show notification to user
- Skip cover, don't crash
- Log error for debugging

### Queue Persistence
- Save queue to SQLite table: `cover_fetch_queue`
- Columns:
  - `game_id` (int, foreign key)
  - `retry_count` (int)
  - `next_retry_at` (int, milliseconds since epoch)
  - `last_error` (text, nullable)
- Load queue on app start
- Clean up completed/failed entries after 7 days

---

## UI Integration

### Settings Screen

**New Elements:**
- "SteamGridDB API Key" section
  - Input field (obscured)
  - Save button
  - Status indicator (key configured/not configured)
- "Get game covers" button
  - Only enabled if API key configured
  - Shows progress during batch operation
- Stats display
  - "X/Y games have covers"
  - "Last fetch: N minutes ago"

### Game Card/Detail

**Visual Changes:**
- Show small loading spinner on placeholder during active fetch
- Smooth transition: placeholder → cover image
- "Change cover" action in detail screen or long-press menu

**Cover Picker UI:**
- Grid layout (2-3 columns)
- Preview images for each option
- Controller-navigable
- Confirm/Cancel buttons

### Add Game Flow

**No Changes:**
- Background fetch happens after save
- User sees placeholder initially
- Cover fills in naturally when ready

### Visual Feedback

**Loading States:**
- Small spinner on placeholder (active fetch)
- Progress bar for batch operations
- No blocking dialogs

**Transitions:**
- Fade-in animation when cover loads
- Immediate update on manual selection

---

## Performance Considerations

### Non-Blocking Operations
- Quick fetch has strict 2-3s timeout
- Background queue runs on idle
- No UI thread blocking
- Downloads happen asynchronously

### Queue Efficiency
- Batch requests where possible
- Process queue in chunks (10 games at a time)
- Respect rate limits
- Pause queue if battery low (optional)

### Caching Strategy
- Don't re-download existing covers
- Check file existence before fetch
- Clean up orphaned files periodically

### Memory Management
- Stream downloads (don't load full image in memory)
- Limit concurrent downloads (max 3)
- Use image caching for UI (Flutter handles this)

---

## Testing Strategy

### Unit Tests

**SteamGridDBService:**
- Mock HTTP responses
- Test timeout behavior
- Test error handling (invalid key, network failure, empty results)
- Test result sorting and auto-selection

**CoverStorageService:**
- Test download and save
- Test file cleanup
- Test disk space handling

**CoverFetchQueue:**
- Test queue persistence (save/load)
- Test retry logic and backoff
- Test queue processing

### Integration Tests

**Add Game Flow:**
- Add game → verify cover fetch triggered
- Failed fetch → verify queued
- Queue retry → verify cover updates

**Manual Change:**
- Trigger "Change cover" → verify picker shows
- Select cover → verify game updates

**Batch Operation:**
- Trigger "Get game covers" → verify all missing covers processed
- Verify progress updates
- Verify completion notification

### Manual Testing

**Real API Key:**
- Test with valid API key
- Verify covers download correctly
- Test various game titles and platforms

**Error Scenarios:**
- Test with missing/invalid API key
- Test with slow network (verify timeout)
- Test offline mode (verify graceful failure)

**Controller Navigation:**
- Test picker UI with controller
- Verify all actions are controller-accessible

**Performance:**
- Quick fetch completes within 2-3 seconds
- Background queue doesn't lag UI
- App remains responsive during batch operations

---

## Implementation Notes

### Phase 1: Core Services
1. Add dependencies to pubspec.yaml
2. Implement SteamGridDBService (API communication)
3. Implement CoverStorageService (download/save)
4. Add unit tests for services

### Phase 2: Queue System
1. Create cover_fetch_queue table in database
2. Implement CoverFetchQueue (queue logic)
3. Add queue persistence tests
4. Integrate queue with game add flow

### Phase 3: UI Integration
1. Add API key input to settings screen
2. Add "Get game covers" button
3. Implement cover picker UI
4. Add "Change cover" action to game detail

### Phase 4: Polish
1. Add loading indicators
2. Add error messages
3. Add success notifications
4. Test controller navigation

---

## Success Criteria

- [ ] Game covers auto-fetch on add (with 2-3s timeout)
- [ ] Failed fetches retry in background
- [ ] Manual "Change cover" shows picker UI
- [ ] Batch "Get game covers" processes all missing covers
- [ ] API key stored in .env file
- [ ] Settings screen shows API key input
- [ ] All operations controller-navigable
- [ ] No UI blocking or lag
- [ ] Graceful error handling (missing key, network failures)
- [ ] Queue persists across app restarts
- [ ] Covers stored in app documents directory

---

## Future Enhancements (Not in Initial Scope)

- Support for other art types (logos, heroes, icons)
- Custom cover upload
- Cover editing/cropping
- Multiple cover variants per game
- Cover metadata (artist, source)
- Cover history/versions
