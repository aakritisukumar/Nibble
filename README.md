# Nibble — AI Calorie Tracker

A Flutter app that lets you track calories by just typing what you ate. No barcode scanning, no food databases to browse — just describe your meal in natural language and get instant nutrition estimates powered by Claude AI.

## Features

- **Conversational food logging** — type "2 eggs and toast" or "KFC Zinger burger" and get instant calorie + macro breakdowns
- **Smart clarification** — if your input is vague, the AI asks one combined question to refine the estimate
- **Daily progress** — live calorie bar with your personal daily goal
- **Macro tracking** — protein, carbs, and fat tracked per entry
- **Summary screen** — today's totals, macro rings, and full history
- **Streak calendar** — monthly view of days you logged food
- **Google Sign-In + Email auth** — with email verification
- **Offline-first** — Hive local storage with Firestore cloud sync

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Dart) |
| State management | Riverpod |
| Local storage | Hive |
| Cloud sync | Firebase Firestore |
| Auth | Firebase Auth (Google + Email) |
| AI backend | Vercel serverless + Claude API (Haiku) |

## Screenshots

_Coming soon_

## Architecture

```
Flutter app (Android)
    ↓ Firebase ID token
Vercel serverless function (/api/parse-food)
    ↓ authenticated request
Claude API (claude-haiku) → JSON nutrition data
    ↓
Hive (local) + Firestore (cloud)
```

The backend verifies every request using Firebase ID tokens — no unauthenticated calls reach the Claude API. A per-user daily limit of 10 messages prevents abuse.

## Download

_APK release coming soon_

## Built With

- [Flutter](https://flutter.dev)
- [Firebase](https://firebase.google.com)
- [Claude API](https://anthropic.com) by Anthropic
- [Vercel](https://vercel.com)
