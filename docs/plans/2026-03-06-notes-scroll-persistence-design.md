# Notes Scroll Persistence - Design

**Date:** 2026-03-06
**Project:** Clair
**Status:** Approved

## Goal
Persist per-note scroll position so reopening a note restores the last scroll offset. Scroll persistence is per device and per note.

## Approach
Use `shared_preferences` to store scroll offsets keyed by note id (e.g., `notes.scroll.<noteId>`). This avoids DB migrations and works across desktop/mobile.

## Architecture
- **Storage:** `shared_preferences`
- **Key format:** `notes.scroll.<noteId>`
- **Read:** on note open, retrieve saved offset
- **Write:** on scroll updates (throttled)

## UI/Behavior
- Apply to both read and edit views using a shared `ScrollController`.
- On open, jump to saved offset after content is built; if none, start at top.
- Clamp offsets to valid scroll extent.

## Testing
- Widget test to verify scroll restore using mocked preferences.
- Edge cases: missing key, invalid offsets, short content.

## Notes
- Cursor persistence is out of scope.
- If notes move to SQLite later, offsets can be migrated.
