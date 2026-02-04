# Technology Stack

## UI Layer

**Flutter (Dart)**

Responsible for:
- Interface rendering
- Input handling
- Animations
- Navigation logic
- View state

⸻

## Core Engine (Optional / Future)

**Rust**

Responsible for:
- Library scanning
- Metadata processing
- Rules evaluation
- Cross-platform logic
- Performance-critical tasks

⸻

## Data Storage

**SQLite**

Clair is local-first and stores:
- Library metadata
- Playtime
- Completion state
- User configuration

⸻

## Architectural Principles

**Separation of Concerns**

Flutter UI → Application Logic → Platform Integration → External Launch Targets

UI must never directly contain platform-specific logic.
