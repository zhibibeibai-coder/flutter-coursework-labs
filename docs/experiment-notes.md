# Experiment Notes

This repository collects the reproducible parts of a Flutter coursework experiment: three small labs and one final assignment app. The goal is to preserve how the work was done while keeping personal submission details out of the public repository.

## Lab 1: Mini Quiz App

The quiz app demonstrates the basic Flutter page structure, Material widgets, state updates, answer selection, score calculation, and simple result feedback. It is useful as a first pass through reactive UI development.

## Lab 2: Mini Contacts App

The contacts app loads sample contact data from a local JSON file, displays a list, supports detail viewing, and uses platform launch behavior for phone-related actions. Public sample data has been anonymized so no real names or phone numbers are included.

## Lab 3: Mini Douban App

The Douban-style app focuses on a media list experience: card layout, images, item details, and fallback data. It is a good reference for combining local assets with network-oriented UI structure.

## Final Assignment: News App

The news app combines the larger set of coursework requirements:

- News list and news detail pages.
- Route navigation between pages.
- Remote image display through sample image URLs.
- Comment submission with an asynchronous mock request.
- Optional image capture or selection for comments.
- SQLite-backed favorites through `sqflite`.
- Layout behavior for portrait and landscape usage.

## Build Notes

Flutter projects can be sensitive to local machine state. Do not commit generated files such as `android/local.properties`, `.flutter-plugins-dependencies`, or build outputs. These files are recreated by Flutter and may contain local SDK paths.

If Gradle, Android SDK, or `aapt` fails because of a non-ASCII directory path, move the project to an ASCII-only path, then run:

```powershell
flutter clean
flutter pub get
flutter run
```

## Privacy Notes

Only source code and public-facing notes are included here. Reports, packaged submissions, screenshots, APK files, local SDK paths, and personally identifying sample data were removed before publishing.
