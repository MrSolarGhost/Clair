Project Overview

Clair is a completion-focused, controller-first game frontend designed to reduce decision fatigue and encourage finishing games.

Clair unifies:
- Emulated games
- Native PC games
- Storefront libraries (Steam, GOG, Epic)
- Android native games

Clair is frontend software, not an emulator and not a storefront.

It launches external software and organizes gaming experiences around calm, intentional play.

⸻

Core Philosophy

Agents working in this repository MUST respect the following principles:

1. Completion Over Consumption

Clair exists to help users finish games, not accumulate them.

Features should:
- Reduce overwhelm
- Highlight meaningful progress
- Encourage intentional play sessions

Avoid:
- Infinite scrolling patterns
- Dopamine-driven engagement loops
- Social-media-style retention mechanics

⸻

2. Calm Interface Design

Clair is designed to feel like a console OS, not a mobile launcher.

UI must:
- Reduce cognitive load
- Emphasize clarity and breathing room
- Use smooth, intentional animation
- Avoid clutter and dense dashboards

⸻

3. Controller-First UX

Every interface MUST be fully navigable using:
- Gamepad
- Keyboard

Touch is supported but never required.

Focus navigation must always be predictable.

⸻

4. Offline-First Architecture

Clair must function fully without internet access.

Online features must be:
- Optional
- Non-blocking
- Fail-safe

⸻

5. Platform-Native Integration

Clair launches and integrates with external software rather than replacing it.

Agents must prefer:
- Native system APIs
- Existing emulator configuration
- Storefront compatibility

Never attempt to replicate emulator functionality.

6. Deterministic Behavior

Clair prioritizes predictability.

Agents must:
- Avoid hidden background processes
- Avoid implicit state mutations
- Prefer explicit data flow

⸻

7. Minimal Abstraction

Clair values clarity over theoretical purity.

Agents should:
- Avoid unnecessary patterns
- Prefer readable solutions
- Avoid over-engineering

⸻

8. Convention Over Configuration

Default behaviors should cover common use cases.

Users should not need to configure:
- Emulator detection
- Game scanning
- Storefront imports

9. Decision Guidelines

When uncertain, agents must prefer solutions that:
1. Reduce user overwhelm
2. Preserve UI calmness
3. Improve reliability
4. Maintain cross-platform parity
5. Keep architecture simple

⸻

10. Future-Safe Design

Agents should assume Clair may expand to:
- Cloud sync
- Multi-device continuity
- Plugin ecosystem
- Save-file management

Architecture should remain extensible without premature complexity.

⸻

11. Contribution Behavior

Agents must:
- Maintain consistent code style
- Avoid introducing experimental dependencies
- Document non-obvious logic
- Preserve platform compatibility

Reference Material

- UI polish/performance updates: consult docs/notes/ui-performance.md and docs/notes/ui.md whenever you are tuning the experience, visuals, or responsiveness.
- Backend/platform work: consult docs/notes/backend.md before touching file scanning, integration, or persistence layers.
- Ops practices: consult docs/notes/ops.md for logging, testing focus, and anti-goals before adding new tooling or workflows.
- Technology stack: consult docs/notes/tech-stack.md when shaping overall architecture or choosing which layer owns a capability.

