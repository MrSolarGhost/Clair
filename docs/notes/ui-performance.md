# UI + Performance Notes

These notes are reference material—consult them when working on experience polish, layout tuning, or performance-critical flows.

## UI Heuristics
- Keep focusable regions large and spaced so controller D-pad navigation never feels cramped.
- Prefer minimal on-screen chrome; every surface should highlight a single objective or set of related actions.
- Favor smooth, intentional animation curves (ease-in-out) with consistent durations so transitions feel calm.
- Touch interactions should bring focus to the touched element; avoid focus jumps that surprise controller users.
- Use subtle depth cues (shadows, elevation) instead of saturated colors to signal hierarchy and affordance.

## Performance Guidance
- Assume the app runs alongside emulators or native games. Avoid background jobs that compete for CPU/GPU unless they respect a low-priority mode.
- Cache library metadata and playstate locally; refresh scans only when the user explicitly requests it or when the host platform triggers a change event.
- Batch writes (notes, guides, profile updates) to SQLite to reduce churn; favor upserts with explicit transactions.
- Avoid large memory spikes during transitions—keep artwork tiling at reasonable resolutions and lazy-load assets as focus shifts.
- Instrument slow operations and expose a “diagnostics” toggle for more verbose logging during development without shipping it permanently.

## Input Consistency
- Controller axis and button mapping must be documented alongside new screens; assume players will reach everything with two sticks and a face cluster.
- Keyboard shortcuts mirror controller actions; updates must stay in sync to avoid drift.
- Touch gestures are optional; never rely on swipes or multi-finger input for critical navigation unless there is a controller-friendly alternative.
