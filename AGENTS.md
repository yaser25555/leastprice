# Repository Guidelines

## Project Structure & Module Organization
LeastPrice is a Flutter application designed for price comparison in Saudi Arabia, integrated with Firebase for backend services and authentication.

- **lib/**: Core application logic.
    - **core/**: Global configurations, themes (`app_palette.dart`), and shared widgets.
    - **features/**: Functional modules containing UI and business logic.
    - **services/**: External API integrations (Firebase, SerpApi, Serper.dev) and search services.
    - **data/**: Data models and repository definitions.
- **lib/features/search/**: New search-related features like `BarcodeScannerScreen`.
- **functions/**: Node.js Firebase Cloud Functions for referral automation and backend tasks.
- **scripts/**: Automation scripts for data fetching (`daily_price_fetcher.py`) and Firestore management.
- **assets/**: Static resources including product data and brand icons.

## Build, Test, and Development Commands

### Flutter App
- **Install dependencies**: `flutter pub get`
- **Run app**: `flutter run`
- **Run analyzer**: `flutter analyze`
- **Run tests**: `flutter test`
- **Build APK**: `flutter build apk --release`
- **Build Web**: `flutter build web --release`

### Firebase Functions
Commands should be run within the `functions/` directory:
- **Deploy functions**: `npm run deploy`
- **Start emulator**: `npm run serve`
- **View logs**: `npm run logs`

### Automation Scripts
Located in `scripts/`:
- **Run price bot**: `python scripts/daily_firestore_price_bot.py`
- **Import coupons**: `python scripts/import_coupons.py`

## Coding Style & Naming Conventions
- **Linter**: Enforced by `flutter_lints` via `analysis_options.yaml`.
- **State Management**: Uses `Riverpod` for state handling.
- **Theme**: Adheres to a strict navy and orange brand palette defined in `lib/core/theme/app_palette.dart`. UI components should follow guidelines in `UI_DESIGN_GUIDELINES.md`.
- **Naming**: Follow standard Dart/Flutter PascalCase for classes and camelCase for variables/functions.

## Commit & Pull Request Guidelines
The project follows a variant of Conventional Commits:
- **feat(category)**: New features or UI changes.
- **style(ui)**: Visual adjustments and brand alignment.
- **fix(area)**: Bug fixes and performance improvements.
- **chore**: Version updates and maintenance tasks.
