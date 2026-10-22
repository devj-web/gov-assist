# GovAssist AI — Flutter Frontend

This is a Flutter frontend starter with a citizen experience plus demo Ward Member and Admin portals.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Frontend areas

- `lib/main.dart`: current welcome, citizen login, dashboard, scheme discovery and scheme detail flow.
- `lib/core/app_colors.dart`: shared color tokens for new modular screens.
- `lib/models/ward_models.dart`: ward citizen and assistance case models.
- `lib/data/ward_demo_data.dart`: illustrative ward records for UI development.
- `lib/screens/ward/ward_portal.dart`: ward dashboard, citizen list, consent interface, assistance cases and follow-ups.
- `lib/screens/admin/admin_portal.dart`: admin overview, ward account/assignment UI, scheme catalogue preview and aggregate reports.

## Important limitations

All account, citizen, scheme, case, consent and report data in these new screens is demo data. Login is not real authentication. The consent toggle is a UI prototype and is not legally meaningful consent or a secure access control. Do not use this demo with real citizen data. Backend authentication, server-side ward authorization, citizen-granted consent records, audit logs, database persistence, scheme verification, and report APIs must be implemented before deployment.

The catalogue count displayed in the admin overview is illustrative; it does not import or verify the supplied scheme CSV.
