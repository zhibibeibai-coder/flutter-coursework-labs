# Flutter Coursework Labs

Public-safe source code and notes for a Flutter mobile development coursework set.

If you are struggling with multi-agent collaboration in your project, this project may be a useful reference.

## Contents

- `apps/mini_quiz_app` - a small quiz app.
- `apps/mini_contacts_app` - a contacts app using local JSON data and launcher-style phone actions.
- `apps/mini_douban_app` - a Douban-style movie list app with local fallback data.
- `apps/news_app` - the final assignment news app with list/detail pages, images, comments, favorites, SQLite persistence, and responsive layout handling.
- `docs/experiment-notes.md` - implementation notes and lessons learned.

## What Is Excluded

This repository intentionally excludes submission packages, APK files, Word/PDF reports, screenshots, local build caches, and machine-specific files. Only source code and public notes are included, so the repository can be shared without personal information.

## Run An App

Install Flutter and Android Studio, then run one app at a time:

```powershell
cd apps/news_app
flutter pub get
flutter run
```

The same flow works for the other apps under `apps/`.

If Android Gradle or `aapt` reports path encoding problems, move the repository to an ASCII-only path and run `flutter clean`, `flutter pub get`, and `flutter run` again.
