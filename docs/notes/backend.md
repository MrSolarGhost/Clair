# Backend & Platform Notes

## Performance Guidelines

Clair must feel instant.

Agents must:
- Avoid blocking UI thread
- Prefer asynchronous file operations
- Cache metadata responsibly
- Minimize redundant scanning

⸻

## File Scanning Rules

Scanning must be:
- Incremental when possible
- Fault-tolerant
- Non-destructive
- Transparent to users

**Never delete or modify user files.**

⸻

## Platform Integration Rules

Agents must:
- Respect OS permissions
- Use platform-specific launch methods
- Avoid brittle path assumptions
- Fail gracefully if external software is missing

⸻

## Data Integrity

Clair data must:
- Survive crashes
- Avoid silent corruption
- Prefer append/update over destructive rewrites
