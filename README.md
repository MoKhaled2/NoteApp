# Notes App

A clean, minimal, and beautiful Notes & Tasks app built with Flutter and Firebase.

## Features

- **Authentication**: Email/Password login and signup.
- **Notes & Tasks**: Create, edit, delete notes. support for plain text and rich details.
- **Media**: Attach images to notes from camera or gallery.
- **Organization**: Tagging, Due Dates, and Favorites.
- **Search**: Fast search across titles and content.
- **Sharing**: Share notes via system share sheet (text + images).
- **Theme**: Light and Dark mode support (Material 3).

## Architecture

This project follows a **Feature-First** architecture with **Riverpod** for state management.

```
lib/
  core/           # Shared utilities (Theme, Router)
  features/
    auth/         # Authentication (Repo, Screens)
    notes/        # Notes (Model, Repo, Screens)
  main.dart       # Entry point
```

## Setup & Running

**Prerequisites**:
- Flutter SDK
- Firebase Project

**Steps**:

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd notes_app
   ```

2. **Configure Firebase**:
   This app uses `flutterfire_cli` for configuration.
   ```bash
   # Install CLI if needed
   dart pub global activate flutterfire_cli
   
   # Run configuration
   flutterfire configure
   ```
   This will generate `firebase_options.dart` in `lib/`.

3. **Uncomment Firebase Initialization**:
   In `lib/main.dart`, uncomment the Firebase initialization lines:
   ```dart
   // await Firebase.initializeApp(
   //   options: DefaultFirebaseOptions.currentPlatform,
   // );
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## Dependencies
- `flutter_riverpod`
- `go_router`
- `firebase_auth`, `cloud_firestore`
- `image_picker`, `share_plus`
- `flutter_animate`
