# SteamGridDB Integration

## Overview

Automatically fetch game cover art from SteamGridDB when adding games to your library.

## Setup

1. Get API key from https://www.steamgriddb.com/profile/preferences/api
2. Open Settings in the app
3. Enter API key under "SteamGridDB API Key"
4. Click "Save API Key"

## Features

### Auto-Fetch
- Covers fetch automatically when adding games
- 3-second timeout for quick results
- Failed fetches retry in background

### Manual Selection
- Tap "Change Cover" on any game
- Browse all available covers
- Select your preferred artwork

### Batch Operations
- Settings → "Get Game Covers"
- Fetches covers for all games without artwork
- Shows progress indicator

## Troubleshooting

**Covers not downloading:**
- Check API key is configured
- Verify internet connection
- Check rate limits (500 requests/hour)

**Wrong cover selected:**
- Use "Change Cover" to pick manually
- Search uses game title + platform for best match

## Technical Details

- Covers saved to app documents directory
- Queue persists across app restarts
- Retry logic: 1min, 5min, 15min intervals
- Failed fetches removed after 3 attempts
