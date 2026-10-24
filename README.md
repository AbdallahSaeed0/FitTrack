# FitTrack

A cross-platform fitness companion built with Flutter. Log strength and cardio workouts, follow programs, track nutrition and see your progress over time.

## Features

- Exercise library with animated GIF demonstrations
- Workout logging for strength and cardio sessions, with a live workout notification
- Programs and reusable workout templates
- Workout history with a calendar view
- Progress analytics and charts
- Nutrition tracking backed by USDA and Open Food Facts data
- Achievements to keep you motivated
- Onboarding wizard, user profiles and authentication
- Share and export workouts, including PDF export

## Tech stack

- Flutter and Dart (Android, iOS, web, Windows, macOS, Linux targets)
- Riverpod for state management
- go_router for navigation
- Supabase as the cloud backend
- fl_chart for charts, pdf and printing for exports
- Dio for HTTP

## Project structure

lib/core - shared configuration and utilities
lib/data - data sources and models
lib/features - one folder per feature (workout, exercises, nutrition, analytics, programs, and more)
lib/shared - shared widgets

## Getting started

1. Install Flutter (Dart SDK 3.0 or newer).
2. Clone the repository and run flutter pub get.
3. Add your own Supabase project URL and anon key in the app configuration.
4. Run flutter run.

## Author

Built by [Abdallah Saeed](https://github.com/AbdallahSaeed0).
