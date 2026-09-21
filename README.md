# TripMate

TripMate is a group-trip planner for friends. A single trip connects the
itinerary, booking slots, preparation tasks, and shared expenses so the group
can plan and settle up in one place.

## MVP flow

1. Sign in and open a shared trip.
2. Choose limited-capacity booking slots such as transport or accommodation.
3. Track preparation work with a team checklist.
4. Record expenses and view the minimum set of transfers needed to settle up.

## Project structure

- `frontend/`: Flutter mobile application with Overview, Planner, and Expenses tabs.
- `backend/`: Django REST API with JWT-protected TripMate endpoints.
- `docs/TRIPMATE_API.md`: ER diagram, enums, endpoint contract, and sprint status.

## Run locally

Start the API from `backend/`:

```powershell
.\.venv\Scripts\python.exe manage.py migrate
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

Run the Flutter app from `frontend/`:

```powershell
flutter pub get
flutter run
```

The API exposes JWT token endpoints at `/api/token/` and
`/api/token/refresh/`, plus authenticated TripMate routes under `/api/trips/`.
See [docs/TRIPMATE_API.md](docs/TRIPMATE_API.md) for the complete contract.

## Next delivery steps

- Replace development JWT login with OIDC Authorization Code + PKCE.
- Add push notifications, CI, and production PostgreSQL configuration.
- Add end-to-end tests against a seeded API environment.
