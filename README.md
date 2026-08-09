# NAUB Padi

Flutter + PHP/MySQL scaffold for the NAUB Question Bank & Repository.

## App structure

- `lib/main.dart` bootstraps the app
- `lib/app.dart` holds the current UI and routing shell
- `lib/core/` contains theme, constants, routes, and app settings
- `lib/models/` contains the domain models
- `lib/services/` contains API/auth/upload/pdf/storage services
- `lib/screens/` contains the feature screens
- `lib/widgets/` contains reusable UI components

## Backend

- `backend/api/` contains the PHP endpoints
- `backend/sql/schema.sql` contains the schema and seed data
- `backend/README.md` explains deployment

## Build

Install dependencies and build the APK with your API URL:

```bash
flutter pub get
flutter build apk --dart-define=NAUB_API_BASE_URL=https://naubpadi.vtutopup.com.ng/api
```

## Notes

- Login/register now return a JWT token from the backend.
- Uploads support up to 10 PDF/JPG/PNG files.
- The browse flow now drills down from faculty to department, level, course, and question papers.
