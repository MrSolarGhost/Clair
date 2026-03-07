# Guides Scroll Persistence - Design

**Date:** 2026-03-06
**Project:** Clair
**Status:** Approved

## Goal
Persist per-guide scroll position so reopening a guide restores the last scroll offset (detail view only).

## Approach
Use `shared_preferences` to store scroll offsets keyed by guide id (e.g., `guides.scroll.<guideId>`). This mirrors the notes scroll persistence and avoids DB migrations.

## Architecture
- **Storage:** `shared_preferences`
- **Key format:** `guides.scroll.<guideId>`
- **Read:** on guide detail open, retrieve saved offset
- **Write:** on scroll updates (throttled)

## UI/Behavior
- Apply only to guide detail view.
- On open, jump to saved offset after first frame; if none, start at top.
- Clamp offsets to valid scroll extent.

## Testing
- Widget test to verify scroll restore using mocked preferences.
- Guard when guide id is null.

## Notes
- List view does not persist scroll.
- If guides move to SQLite later, offsets can be migrated.
