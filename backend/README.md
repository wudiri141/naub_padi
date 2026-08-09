# NAUB Padi backend

Deploy the contents of `backend/api` to `https://naubpadi.vtutopup.com.ng/api/` and import `backend/sql/schema.sql` into the MySQL database `vtutopup_naubpadi`.

## Required database settings

- Database: `vtutopup_naubpadi`
- User: `vtutopup_naubpadi`
- Password: use the credential you provided during setup
- Host: `localhost` on standard shared hosting, unless your host says otherwise

## Endpoints

- `POST /api/login.php`
- `POST /api/register.php`
- `GET /api/faculties.php`
- `GET /api/departments.php`
- `GET /api/courses.php`
- `GET /api/papers.php`
- `POST /api/upload.php`
- `POST /api/bookmark.php`
- `GET /api/profile.php`
- `POST /api/profile.php`
- `GET /api/notifications.php`

## Flutter app

Set the API base URL at build time if needed:

```bash
flutter build apk --dart-define=NAUB_API_BASE_URL=https://naubpadi.vtutopup.com.ng/api
```


## File viewer endpoint

The Flutter app now serves uploaded PDFs and images through:

`/api/file.php?id=FILE_ID`

Deploy `api/file.php` to the same `backend/api/` directory as the other API endpoints. Keep uploaded files in the existing `uploads/` directory. Do not create `backend/backend/`.
