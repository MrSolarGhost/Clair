# Game Card Design

## Goal
Add a full-screen Game Card detail page as the central hub for a game, accessible from Play, Collections, and Home widgets.

## Selected Approach
Single GameCardScreen used by all entry points.

## Architecture
- New `GameCardScreen` (full-screen) displays a game and its actions.
- Navigation from Play, Collections, and Home tiles opens GameCardScreen.
- Uses SQLite `games` table via DatabaseService for core fields.
- Notes/Guides/Achievements show mock panels until those modules are wired.
- Launch action is mocked for now.

## Components
- **GameCardScreen** (`lib/screens/game_card_screen.dart`)
  - Input: game id (or Game model)
  - Load game via DatabaseService
  - Render: cover, title/system, status chip, last played, play time
  - Actions: Launch (mock), Change Status, Notes, Guides, Achievements, Collections
- **Navigation hooks** from Play, Collections, Home widgets
- **Mock panels** for notes/guides/achievements when data is not wired

## Data Flow
1. Game tile tap → navigate to GameCardScreen with game id
2. GameCardScreen loads game from DatabaseService
3. Status change updates `games.status` and refreshes UI
4. Launch action triggers mock behavior (snackbar)
5. Notes/Guides/Achievements open their screens; show placeholder counts if not wired

## Error Handling
- Game id not found: prevent navigation upstream; if reached, show empty state + back
- DB load failure: show error banner + retry

## Testing
- Widget test: GameCardScreen renders title/status for given game
- Service test: status update persists in DatabaseService (if method added)
